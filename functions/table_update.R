# Required libraries
library(dplyr)
library(tidyr)

#' Update a database table with corrections
#'
#' @param table_to_update Main database table with key field
#' @param table_with_corrections Corrections table with match_id, correcting_match, 
#'        duplicate flag, and columns prefixed with "." for updates
#' @param main_key Name of key field in table_to_update (default: "id_CC")
#' @param match_key Name of match key field in table_with_corrections (default: "match_id")
#' @param correcting_key Name of correcting match field (default: "correcting_match")
#' @param duplicate_flag Name of duplicate flag field (default: "Duplicate")
#' @return Updated database table
#' @details 
#' - Rows with "unlink" in correcting_key are excluded from processing
#' - Rows with duplicate_flag == "0" are removed from the main table
#' - Rows with duplicate_flag == "1" or NA are updated with non-NA "." prefixed values
table_update <- function(table_to_update, 
                         table_with_corrections,
                         main_key = "id_CC",
                         match_key = "match_id",
                         correcting_key = "correcting_match",
                         duplicate_flag = "Duplicate",
                         comment = "Comment") {
  
  # Validate inputs
  if (!(main_key %in% names(table_to_update))) {
    stop(paste0("table_to_update must have a '", main_key, "' column"))
  }
  
  required_cols <- c(match_key, correcting_key, duplicate_flag)
  missing_cols <- setdiff(required_cols, names(table_with_corrections))
  if (length(missing_cols) > 0) {
    stop(paste0("table_with_corrections is missing required columns: ", 
                paste(missing_cols, collapse = ", ")))
  }
  
  # Step 1: Establish key to relate corrections to main table
  corrections_with_key <- table_with_corrections %>%
    mutate(
      key_to_main = case_when(
        # If correcting_key contains "unlink", set key to NA (will be filtered out)
        grepl("unlink", .data[[correcting_key]], ignore.case = TRUE) ~ NA_character_,
        # If correcting_key is numeric/integer-like, use it
        !is.na(.data[[correcting_key]]) & !grepl("\\D", .data[[correcting_key]]) ~ .data[[correcting_key]],
        # Otherwise, use match_key
        TRUE ~ .data[[match_key]]
      ),
      # Convert key to integer for joining
      key_to_main = as.integer(key_to_main)
    )
  
  # Step 2: Separate unlinked rows (to be excluded from processing)
  unlinked_rows <- corrections_with_key %>%
    filter(is.na(key_to_main))
  
  unlinked_count <- nrow(unlinked_rows)
  
  # Filter out unlinked rows from corrections
  corrections_to_process <- corrections_with_key %>%
    filter(!is.na(key_to_main))
  
  # Step 3: Identify and remove duplicate rows (duplicate_flag == "0")
  duplicate_ids <- corrections_to_process %>%
    filter(.data[[duplicate_flag]] == "0") %>%
    pull(key_to_main) %>%
    na.omit()
  
  # Remove duplicate rows from main table
  ids_to_remove <- unique(duplicate_ids)
  
  # Remove these rows from main table
  table_filtered <- table_to_update %>%
    filter(!(.data[[main_key]] %in% ids_to_remove))
  
  
  # Step 4: Identify and remove comments with "Remove" flag 
  remove_ids <- corrections_to_process %>%
    filter(grepl("remove", .data[[comment]], ignore.case = TRUE)) %>%
    pull(key_to_main) %>%
    na.omit()
  
  # Remove duplicate rows from main table
  ids_to_remove <- unique(remove_ids)
  
  # Remove these rows from main table
  table_filtered <- table_to_update %>%
    filter(!(.data[[main_key]] %in% ids_to_remove))
  
  # Step 5: Prepare updates for remaining rows (duplicate_flag == "1" or NA)
  corrections_for_update <- corrections_to_process %>%
    filter(.data[[duplicate_flag]] != "0" | is.na(.data[[duplicate_flag]]))
  
  # Identify columns with "." prefix that have updates
  dot_columns <- names(corrections_for_update)[grepl("^\\.", names(corrections_for_update))]
  
  if (length(dot_columns) == 0) {
    message("No update columns (prefixed with '.') found in corrections table")
    return(table_filtered)
  }
  
  # Perform left join using dynamic key names
  # Only select key and dot columns from corrections to avoid conflicts
  corrections_select <- corrections_for_update %>%
    select(key_to_main, all_of(dot_columns))
  
  join_spec <- setNames("key_to_main", main_key)
  table_joined <- table_filtered %>%
    left_join(corrections_select, by = join_spec)
  
  # Step 6: Update values from "." prefixed columns to their base columns
  for (dot_col in dot_columns) {
    # Get the base column name (remove leading ".")
    base_col <- sub("^\\.", "", dot_col)
    
    # Check if base column exists in the main table
    if (base_col %in% names(table_filtered)) {
      # Update: use correction value if not NA, otherwise keep original
      # Handle both numeric and character columns appropriately
      table_joined <- table_joined %>%
        mutate(!!base_col := ifelse(!is.na(.data[[dot_col]]), 
                                    .data[[dot_col]], 
                                    .data[[base_col]]))
    } else {
      warning(paste0("Column '", base_col, "' not found in table_to_update. Skipping update for '", dot_col, "'"))
    }
  }
  
  # Step 7: Clean up - remove correction columns and keep only original columns
  original_columns <- names(table_filtered)
  table_updated <- table_joined %>%
    select(all_of(original_columns))
  
  # Print summary
  message(sprintf("Rows removed from corrections table (unlinked): %d", unlinked_count))
  message(sprintf("Rows removed from main table (duplicates): %d", length(duplicate_ids)))
  message(sprintf("Rows removed from main table (remove flag): %d", length(remove_ids)))
  message(sprintf("Rows updated: %d", nrow(corrections_for_update)))
  message(sprintf("Final row count: %d (was %d)", nrow(table_updated), nrow(table_to_update)))
  
  return(table_updated)
}


# ===== LOAD TEST DATA AND APPLY THE FUNCTION (deactivate if(FALSE))=====

if (FALSE) {

corrections.test <- data.frame(
  match_id = c(NA, "9", "13", "18", "28", "29"), 
  correcting_match = c("unlink, record via iDigBio", NA, NA, "good", NA, NA), 
  Duplicate = c("0", "0", "0", "1", NA, NA), 
  Comment = c("0", "0", "0", "1", NA, "This case should be removed."),
  .references = c(NA, NA, NA, NA, NA, NA), 
  .associatedReferences = c(NA, NA, NA, "XXX_assoRef", NA, NA), 
  .decimalLatitude = c(NA, NA, NA, NA, NA, "+9999999"), 
  .decimalLongitude = c(NA, NA, NA, NA, NA, "-9999999"), 
  .locality = c(NA, NA, NA, NA, NA, "XXX_local"), 
  .year = c(NA, NA, NA, NA, NA, NA), 
  .eventDate = c(NA, NA, NA, NA, NA, NA), 
  .bibliographicCitation = c(NA, NA, NA, NA, "XXX_biblio", NA), 
  .canonicalName = c(NA, NA, NA, NA, NA, NA), 
  .scientificName = c(NA, NA, NA, NA, NA, NA), 
  .catalogNumber = c(NA, NA, NA, NA, NA, NA), 
  .recordedBy = c(NA, NA, NA, NA, NA, NA), 
  .occurrenceID = c(NA, NA, NA, NA, NA, NA),
  stringsAsFactors = FALSE
)


database.test <- data.frame(
  id_CC = c(18, 9, 13, 28, 29), 
  references = c(NA, "http://portal.vertnet.org/o/...", "Thompson WF (1916) ...", NA, "-"), 
  associatedReferences = c(NA, NA, NA, NA, NA), 
  decimalLatitude = c(-50.386, -46.83, -46.8333333329, -47.81, -47.7499999998), 
  decimalLongitude = c(-75.251, -75.3, -75.2999999996, -74.764, -74.7499999998), 
  locality = c("Rio Tote. Isla Madre de Dios", "Port Otway", "Port Otway", "Canal Messier. Isla Juan Stuven", "Isla Harbor"), 
  year = c(2014, 1888, NA, NA, NA), 
  eventDate = c("2014-4-24", "1888", NA, NA, NA), 
  bibliographicCitation = c("OrigenReg: Base de Datos EULA UdeC, FuenteReg: Base Datos 2014", 
                            "National Museum of Natural History, Smithsonian ...", 
                            "Rademacher K. 2007... ", 
                            "FuenteReg: Gunther 1980 Estudio: Campos et al. 1993b", 
                            "Zama A. y Cárdenas E. 1984..."), 
  canonicalName = c("Galaxias maculatus", "Eleginops maclovinus", "Galaxias maculatus", "Aplochiton zebra", "Aplochiton taeniatus"), 
  scientificName = c("Galaxias maculatus (Jenyns, 1842)", "Eleginops maclovinus (Cuvier, 1830)", 
                     "Galaxias maculatus (Jenyns, 1842)", "Aplochiton zebra Jenyns, 1842", 
                     "Aplochiton taeniatus Jenyns, 1842"), 
  catalogNumber = c(NA, "77318", "1082", NA, "1352"), 
  recordedBy = c("Evelyn Habit", NA, NA, NA, NA), 
  occurrenceID = c("MMA:ICT:0002019", "http://n2t.net/ark:...", NA, "MMA:ICT:0000206", NA),
  stringsAsFactors = FALSE
)





# ===== RUN TEST  =====



# With default field names (as before)
result <- table_update(
  table_to_update = database.test,
  table_with_corrections = corrections.test
)

# With custom field names
result <- table_update(
  table_to_update = database.test,
  table_with_corrections = corrections.test,
  main_key = "id_CC",
  match_key = "match_id",
  correcting_key = "correcting_match",
  duplicate_flag = "Duplicate",
  comment = "Comment" 
)


}




