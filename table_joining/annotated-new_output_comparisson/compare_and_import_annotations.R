
# =====================================================================
# import_annotations() — Import Reviewed Annotations by Composite Key
# =====================================================================
#
# This function helps migrate manually reviewed annotations (e.g., 
# match corrections) from an older version of a dataset (`table_old`) 
# to a newly generated version (`table_new`).
#
# It matches rows based on a customizable set of key columns 
# (default: id_CC_original + match_id) and imports the annotation 
# column (default: "correcting_match") into the new table.
#
# The function also adds diagnostic columns to the output for easy 
# filtering and manual review. These indicate whether each row was 
# previously reviewed, whether the annotation was successfully 
# imported, and whether the original ID or match has changed.
#
# Output:
# - `updated_table`: Copy of the new table with annotations and diagnostics
# - `diagnostics`: Summary stats and rows needing review
#
# Ideal for use in iterative data matching, de-duplication, and 
# validation workflows.

# Required libraries
library(dplyr)
library(tidyr)

#' Import annotations from a previously reviewed table to a new table
#'
#' @param table_old Previously reviewed table with annotations
#' @param table_new New table to receive annotations
#' @param key_columns Vector of column names to create the matching key (default: c("id_CC_original", "match_id"))
#' @param annotation_column Name of the annotation column to import (default: "correcting_match")
#' @param original_id_col Name of the original ID column for diagnostics (default: "id_CC_original")
#' @param match_id_col Name of the match ID column for diagnostics (default: "match_id")
#' @return List with two elements: updated_table and diagnostics
#' @details
#' ### Diagnostic Columns Added to `updated_table`
#' 
#' The function not only imports annotations into the new table, but also adds 
#' diagnostic fields that help assess whether each row has been previously reviewed and 
#' whether the annotation was imported successfully. These appear as the last columns 
#' in `updated_table`:
#'
#' | Column Name | Description |
#' |------------|-------------|
#' | **row_status** | High‑level classification: <br>• `"existing_in_old"` — this composite key (ID + match) was previously reviewed <br>• `"new_in_new"` — this row is new and needs review |
#' | **key_found_in_old** | `TRUE` if an exact composite key match was found in `table_old`; otherwise `FALSE` |
#' | **id_in_old** | `TRUE` if the `id_CC_original` value exists in `table_old`, even if the match differs |
#' | **old_composite_key_if_exists** | Shows the matching composite key from the old table when found, otherwise `NA` |
#' | **matched_annotation_imported** | `TRUE` if an annotation from `table_old` was imported; `FALSE` if manual review is required |
#'
#' These fields allow spreadsheet‑friendly filtering to triage review work:
#'
#' • Rows needing manual review:  
#' `subset(updated_table, !matched_annotation_imported)`
#'
#' • New IDs not present in the old table:  
#' `subset(updated_table, !id_in_old)`
#'
#' • Same ID but new match (new relationship):  
#' `subset(updated_table, id_in_old & !key_found_in_old)`
#'
#' • Fully validated imported annotations:  
#' `subset(updated_table, matched_annotation_imported)`
#'
#' In short, these diagnostics simplify tracking of annotation completeness and help 
#' isolate newly introduced records or changed match assignments for targeted review.  


# Load function ####

import_annotations <- function(table_old,
                               table_new,
                               key_columns = c("id_CC_original", "match_id"),
                               annotation_column = "correcting_match",
                               original_id_col = "id_CC_original",
                               match_id_col = "match_id") {
  
  # Convert all columns to character for consistency
  table_old <- table_old %>% mutate(across(everything(), as.character))
  table_new <- table_new %>% mutate(across(everything(), as.character))
  
  # Input validation
  if (!all(key_columns %in% names(table_old)))
    stop("Old table missing key columns: ", paste(setdiff(key_columns, names(table_old)), collapse=", "))
  if (!all(key_columns %in% names(table_new)))
    stop("New table missing key columns: ", paste(setdiff(key_columns, names(table_new)), collapse=", "))
  if (!(annotation_column %in% names(table_old)))
    stop("Old table missing annotation column: ", annotation_column)
  
  cat("\n========================================\n")
  cat("IMPORTING ANNOTATIONS\n")
  cat("========================================\n\n")
  
  # Create composite key
  create_key <- function(df) {
    df$.composite_key <- apply(df[key_columns], 1, function(x) {
      paste(ifelse(is.na(x), "NA", x), collapse = "___")
    })
    return(df)
  }
  
  table_old_keyed <- create_key(table_old)
  table_new_keyed <- create_key(table_new)
  
  # Build lookup for annotations
  lookup <- table_old_keyed %>%
    select(.composite_key, all_of(annotation_column)) %>%
    distinct()
  
  # Merge into new table
  table_updated <- table_new_keyed %>%
    left_join(lookup, by = ".composite_key") %>%
    mutate(!!annotation_column := .data[[annotation_column]]) %>%
    relocate(!!annotation_column, .after = all_of(match_id_col))
  
  # Add diagnostic columns before filtering
  table_updated <- table_updated %>%
    mutate(
      key_found_in_old = .composite_key %in% table_old_keyed$.composite_key,
      id_in_old = .data[[original_id_col]] %in% table_old[[original_id_col]],
      row_status = ifelse(key_found_in_old, "existing_in_old", "new_in_new"),
      old_composite_key_if_exists = ifelse(key_found_in_old, .composite_key, NA_character_),
      matched_annotation_imported = !is.na(.data[[annotation_column]])
    )
  
  # Count diagnostics
  rows_annotated <- sum(table_updated$matched_annotation_imported)
  rows_review <- sum(!table_updated$matched_annotation_imported)
  
  diagnostics <- list(
    summary = data.frame(
      metric = c(
        "Rows with imported annotations",
        "Rows needing manual review (no annotation)",
        "Total rows in new table"
      ),
      count = c(
        rows_annotated,
        rows_review,
        nrow(table_new)
      ),
      stringsAsFactors = FALSE
    ),
    
    rows_needing_review = table_updated %>%
      filter(!matched_annotation_imported) %>%
      select(all_of(c(original_id_col, match_id_col,
                      annotation_column,
                      "row_status", "key_found_in_old", "id_in_old",
                      "old_composite_key_if_exists")))
  )
  
  # Console summary
  cat("=== SUMMARY ===\n")
  print(diagnostics$summary, row.names = FALSE)
  if (rows_review > 0) {
    cat(sprintf("WARNING: %d rows need manual review\n", rows_review))
  }
  cat("Done!\n\n")
  
  # Final cleanup and column order
  table_updated <- table_updated %>%
    select(-.composite_key) %>%
    relocate(row_status, .after = last_col()) %>%
    relocate(key_found_in_old, id_in_old, old_composite_key_if_exists, matched_annotation_imported,
             .after = row_status)
  
  return(list(
    updated_table = table_updated,
    diagnostics = diagnostics
  ))
}



# ===== TEST WITH SAMPLE DATA ===== ####

if (FALSE) {
  
  table1.annotated <- data.frame(
    id_CC_original = c(14, 16, 18, 26, 44, 45), 
    match_id = c(NA, 9, 13, 18, 28, 29), 
    correcting_match = c("unlink, record via iDigBio", NA, NA, "good", NA, NA), 
    n_keys_used = c(NA, 3, 3, 4, 3, 3), 
    match_keys_used = c(NA, 
                        "datasetName;canonicalName;decimalLatitude", 
                        "datasetName;canonicalName;decimalLatitude", 
                        "datasetName;canonicalName;decimalLatitude;decimalLongitude", 
                        "datasetName;canonicalName;decimalLatitude", 
                        "datasetName;canonicalName;decimalLatitude")
  )
  
  table1_output.new <- data.frame(
    id_CC_original = c("14", "16", "18", "26", "39", "40"), 
    match_id = c(NA, 9, 13, 18, 25, 26), 
    n_keys_used = c(NA, 3, 3, 4, 3, 3), 
    match_keys_used = c(NA, 
                        "datasetName;canonicalName;decimalLatitude", 
                        "datasetName;canonicalName;decimalLatitude", 
                        "datasetName;canonicalName;decimalLatitude;decimalLongitude", 
                        "datasetName;canonicalName;decimalLatitude", 
                        "datasetName;canonicalName;decimalLatitude")
  )
  
  # Run the import
  result <- import_annotations(
    table_old = table1.annotated,
    table_new = table1_output.new,
    key_columns = c("id_CC_original", "match_id"),
    annotation_column = "correcting_match"
  )
  
  # Access results
  updated_table <- result$updated_table
  diagnostics <- result$diagnostics
  
  diagnostics$rows_needing_review
  
  # View updated table
  View(updated_table)
  
  # View specific diagnostics
  View(diagnostics$summary)
  View(diagnostics$changed_matches)
  View(diagnostics$rows_needing_review)
}