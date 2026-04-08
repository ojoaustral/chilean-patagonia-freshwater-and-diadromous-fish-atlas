# Required libraries
library(dplyr)
library(stringr)

#' Validate corrections table against main database
#'
#' @param table_main Main database table
#' @param table_corrections Corrections table
#' @param main_key Key field in main table (default: "id_CC")
#' @param match_key Match key field in corrections table (default: "match_id")
#' @param correcting_key Correcting match field (default: "correcting_match")
#' @param check_columns Columns to verify for consistency (default: common fields)
#' @return TRUE if all checks pass, FALSE otherwise (also removes corrections object)
validate_corrections <- function(table_main, 
                                 table_corrections,
                                 main_key = "id_CC",
                                 match_key = "match_id",
                                 correcting_key = "correcting_match",
                                 check_columns = c("datasetName", "canonicalName", 
                                                   "locality", "decimalLatitude")) {
  
  # Standardize fields for comparison   
  standardize_for_matching <- function(df) {
    df %>%
      mutate(
        # Coordinates: ensure numeric (no rounding to preserve precision)
        decimalLatitude  = as.numeric(decimalLatitude),
        decimalLongitude = as.numeric(decimalLongitude),
        
        # Event date: extract YYYY-MM-DD format
        eventDate = if_else(
          is.na(eventDate),
          NA_character_,
          str_sub(as.character(eventDate), 1L, 10L)
        ),
        
        # Year: from year column or extract from eventDate
        year = {
          y1 <- suppressWarnings(as.integer(year))
          y2 <- suppressWarnings(as.integer(str_extract(eventDate, "\\d{4}")))
          coalesce(y1, y2)
        },
        
        # Bibliographic citation: first 20 chars (avoid minor variations)
        bibliographicCitation = str_sub(
          str_trim(as.character(bibliographicCitation)),
          1, 20
        ),
        
        # Text fields: trim, lowercase, standardize NAs
        across(
          c(canonicalName, locality, datasetName, catalogNumber,
            occurrenceID, institutionCode),
          ~ {
            x <- str_to_lower(str_trim(as.character(.x)))
            x[x %in% c("", "na", "n a", "n/a")] <- NA_character_
            x
          }
        ),
        
        # Dataset name: standardize known variations
        datasetName = case_when(
          datasetName %in% c("subpesca-1", "subpesca-2",
                             "fish database correa-boisjoly",
                             "fishgis_metadatabase_ccorrea") ~ datasetName,
          TRUE ~ str_sub(datasetName, 1L, 4L)
        )
      )
  }
  
  # Apply standardization to both tables
  table_main <- standardize_for_matching(table_main)
  table_corrections <- standardize_for_matching(table_corrections)
  
  cat("\n========================================\n")
  cat("DIAGNOSTIC CHECKS: Corrections vs Database\n")
  cat("========================================\n\n")
  
  all_checks_passed <- TRUE
  
  # ===== CHECK 1: Required columns exist =====
  cat("CHECK 1: Verifying required columns...\n")
  
  if (!(main_key %in% names(table_main))) {
    warning(sprintf("FAILED: Main table missing key column '%s'", main_key))
    all_checks_passed <- FALSE
  } else {
    cat(sprintf("  ✓ Main table has key column '%s'\n", main_key))
  }
  
  required_correction_cols <- c(match_key, correcting_key)
  missing_cols <- setdiff(required_correction_cols, names(table_corrections))
  if (length(missing_cols) > 0) {
    warning(sprintf("FAILED: Corrections table missing columns: %s", 
                    paste(missing_cols, collapse = ", ")))
    all_checks_passed <- FALSE
  } else {
    cat(sprintf("  ✓ Corrections table has required columns\n"))
  }
  
  # ===== CHECK 2: All match_ids exist in main database =====
  cat("\nCHECK 2: Verifying all match_ids exist in main database...\n")
  
  # Get all potential keys from corrections table
  corrections_keys <- table_corrections %>%
    mutate(
      key_to_check = case_when(
        grepl("unlink", .data[[correcting_key]], ignore.case = TRUE) ~ NA_character_,
        !is.na(.data[[correcting_key]]) & !grepl("\\D", .data[[correcting_key]]) ~ .data[[correcting_key]],
        TRUE ~ .data[[match_key]]
      ),
      key_to_check = as.integer(key_to_check)
    ) %>%
    filter(!is.na(key_to_check)) %>%
    pull(key_to_check) %>%
    unique()
  
  main_keys <- table_main %>%
    pull(.data[[main_key]]) %>%
    unique()
  
  missing_keys <- setdiff(corrections_keys, main_keys)
  
  if (length(missing_keys) > 0) {
    warning(sprintf("FAILED: %d match_id(s) from corrections not found in main database:", 
                    length(missing_keys)))
    warning(sprintf("  Missing IDs: %s", paste(head(missing_keys, 10), collapse = ", ")))
    if (length(missing_keys) > 10) {
      warning(sprintf("  ... and %d more", length(missing_keys) - 10))
    }
    all_checks_passed <- FALSE
  } else {
    cat(sprintf("  ✓ All %d match_ids found in main database\n", length(corrections_keys)))
  }
  
  # ===== CHECK 3: Non-prefixed columns match between tables =====
  cat("\nCHECK 3: Verifying consistency of non-prefixed columns...\n")
  
  # Find which check_columns exist in both tables
  available_check_cols <- intersect(check_columns, names(table_main))
  available_check_cols <- intersect(available_check_cols, names(table_corrections))
  
  if (length(available_check_cols) == 0) {
    cat("  ⚠ No common columns to check (this may be expected)\n")
  } else {
    cat(sprintf("  Checking %d columns: %s\n", 
                length(available_check_cols),
                paste(available_check_cols, collapse = ", ")))
    
    # Prepare corrections table with keys
    corrections_with_key <- table_corrections %>%
      mutate(
        key_for_join = case_when(
          grepl("unlink", .data[[correcting_key]], ignore.case = TRUE) ~ NA_character_,
          !is.na(.data[[correcting_key]]) & !grepl("\\D", .data[[correcting_key]]) ~ .data[[correcting_key]],
          TRUE ~ .data[[match_key]]
        ),
        key_for_join = as.integer(key_for_join)
      ) %>%
      filter(!is.na(key_for_join))
    
    # Join and compare
    if (nrow(corrections_with_key) > 0) {
      # Select only the columns we need to compare plus the key
      main_subset <- table_main %>%
        select(all_of(c(main_key, available_check_cols)))
      
      corr_subset <- corrections_with_key %>%
        select(key_for_join, all_of(available_check_cols))
      
      comparison <- main_subset %>%
        inner_join(corr_subset, 
                   by = setNames("key_for_join", main_key),
                   suffix = c("_main", "_corr"))
      
      mismatches_found <- FALSE
      
      for (col in available_check_cols) {
        main_col <- paste0(col, "_main")
        corr_col <- paste0(col, "_corr")
        
        if (main_col %in% names(comparison) && corr_col %in% names(comparison)) {
          # Compare values (accounting for NA)
          mismatches <- comparison %>%
            filter(
              !is.na(.data[[main_col]]) & 
                !is.na(.data[[corr_col]]) &
                as.character(.data[[main_col]]) != as.character(.data[[corr_col]])
            )
          
          if (nrow(mismatches) > 0) {
            warning(sprintf("  FAILED: Column '%s' has %d mismatches", col, nrow(mismatches)))
            
            # Show examples - keep original columns for display
            examples <- mismatches %>%
              head(10)
            
            # Show the key and both versions of the mismatched column
            display_cols <- c(main_key, main_col, corr_col)
            display_cols <- intersect(display_cols, names(examples))
            
            if (length(display_cols) > 0) {
              cat("\n  Example mismatches:\n")
              cat("  ", paste(rep("-", 80), collapse = ""), "\n")
              
              examples_display <- examples %>%
                select(all_of(display_cols))
              
              # Print with better formatting
              for (i in 1:nrow(examples_display)) {
                cat(sprintf("  Row %d:\n", i))
                cat(sprintf("    %s: %s\n", main_key, examples_display[[main_key]][i]))
                cat(sprintf("    Main DB:     %s\n", examples_display[[main_col]][i]))
                cat(sprintf("    Corrections: %s\n", examples_display[[corr_col]][i]))
                if (i < nrow(examples_display)) cat("\n")
              }
              
              cat("  ", paste(rep("-", 80), collapse = ""), "\n\n")
            } else {
              cat("\n  (Unable to display examples - column names not found)\n\n")
            }
            
            mismatches_found <- TRUE
            all_checks_passed <- FALSE
          } else {
            cat(sprintf("  ✓ Column '%s' matches (%d rows checked)\n", 
                        col, nrow(comparison)))
          }
        }
      }
      
      if (!mismatches_found && length(available_check_cols) > 0) {
        cat("  ✓ All checked columns are consistent\n")
      }
    }
  }
  
  # ===== CHECK 4: Verify prefixed columns exist in main table =====
  cat("\nCHECK 4: Verifying update columns (prefixed with '.') have targets...\n")
  
  dot_columns <- names(table_corrections)[grepl("^\\.", names(table_corrections))]
  
  if (length(dot_columns) == 0) {
    cat("  ⚠ No update columns found (no columns prefixed with '.')\n")
  } else {
    missing_targets <- c()
    for (dot_col in dot_columns) {
      base_col <- sub("^\\.", "", dot_col)
      if (!(base_col %in% names(table_main))) {
        missing_targets <- c(missing_targets, base_col)
      }
    }
    
    if (length(missing_targets) > 0) {
      warning(sprintf("  WARNING: %d target columns not found in main database:", 
                      length(missing_targets)))
      warning(sprintf("    %s", paste(missing_targets, collapse = ", ")))
      cat("  These updates will be skipped during table_update()\n")
    } else {
      cat(sprintf("  ✓ All %d update columns have corresponding targets\n", 
                  length(dot_columns)))
    }
  }
  
  # ===== FINAL VERDICT =====
  cat("\n========================================\n")
  if (all_checks_passed) {
    cat("RESULT: ✓ ALL CHECKS PASSED\n")
    cat("========================================\n\n")
    cat("Safe to proceed with table_update()\n\n")
    return(TRUE)
  } else {
    cat("RESULT: ✗ CHECKS FAILED\n")
    cat("========================================\n\n")
    warning("CRITICAL: Corrections table does not match database version!")
    warning("Please fix the mismatches before proceeding with table_update().")
    
    cat("\nDO NOT proceed with table_update() until issues are resolved.\n\n")
    
    return(FALSE)
  }
}


# ===== EXAMPLE USAGE =====

if (FALSE) {
  # In your main .Rmd workflow:
  
  # Load your data
  X.filtered.dedup <- read.csv("data/X.filtered.dedup.csv")
  CM <- read.csv("data/CM.csv")
  
  # Run diagnostic checks
  checks_passed <- validate_corrections(
    table_main = X.filtered.dedup,
    table_corrections = CM,
    main_key = "id_CC",
    match_key = "match_id",
    correcting_key = "correcting_match",
    check_columns = c("datasetName", "canonicalName", "locality", "decimalLatitude")
  )
  
  # Only proceed if checks passed
  if (checks_passed) {
    # Load the update function
    source("./functions/table_update.R")
    
    # Run the update
    result <- table_update(
      table_to_update = X.filtered.dedup,
      table_with_corrections = CM
    )
  } else {
    stop("Cannot proceed: corrections table validation failed")
  }
}