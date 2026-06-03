# This script has some minimum handling to check and get Maryse's addenda ready. 


setwd("C:/Users/crist/Documents/GitHub/Atlas_Ictiogeografico/data_sources/Addendum_MBoisjoly/")

X <- read.csv("2026-05-31_Addendum_MBoisjoly.csv", fileEncoding = "UTF-8", 
              colClasses = "character", stringsAsFactors = FALSE)

ScN <- read.csv("../../input_parameters/AtlasIctiogeográfico_list of taxa_annotated_2026.csv", 
                fileEncoding = "UTF-8", colClasses = "character", stringsAsFactors = FALSE)

tmp <- unique(X$scientificName)
tmp <- tmp[!(tmp %in% ScN$scientificName_Old)]
X$scientificName[X$scientificName %in% tmp] <- "Aplochiton zebra Jenyns, 1842"

# Se confirmó que todas las variantes de `scientificName` estuviesen contenidas en la lista anotada de taxa. 
tmp <- unique(X$scientificName)
all(tmp %in% ScN$scientificName_Old) 

## Build a clean lookup table from ScN with filds that will be copied. 
taxonomy <- ScN %>% 
  select(
    scientificName_Old, # keep old name
    scientificName_new = scientificName, # interim name
    canonicalName,
    IncludePewProAP,
    rank,
    kingdom,
    phylum,
    order,
    family,
    genus,
    species
  ) %>% distinct() %>% arrange(order, family, genus, scientificName_new)


# Remove taxonomy columns to fully replace/update
X <- X %>% select(-any_of(c(
  "canonicalName",
  "rank",
  "kingdom",
  "phylum",
  "order",
  "family",
  "genus",
  "species"))) %>%
  # Keep original scientificName for matching
  mutate(scientificName_Old = scientificName) %>%
  # Join taxonomy info
  left_join(taxonomy, by = "scientificName_Old") %>%
  # Update scientificName if a new one is available
  mutate(scientificName = coalesce(scientificName_new, scientificName)) %>%
  # Drop helper columns
  select(-scientificName_new, -scientificName_Old, -IncludePewProAP) %>% 
  # Sort by biblio
  arrange(bibliographicCitation,year, locality, canonicalName) %>% 
  # Create occurrenceID.
  mutate(occurrenceID = paste0("Boisjoly.Lit.Review.", sprintf("%04d", row_number()))) %>% 
  relocate(occurrenceID) 

        
# taxcheck <- X %>%
#   select(scientificName_Old, scientificName, canonicalName, rank,
#     kingdom, phylum, order, family, genus, species) %>%
#   distinct() %>%
#   arrange(scientificName)
# 
# 
# all(taxcheck$scientificName_Old == taxcheck$scientificName)

# colnames(X)

tail(X)

# X.filtered.dedup %>% select(occurrenceID, recordedBy) %>% filter(recordedBy == "Cristian Correa" )

write.csv(X, "2026-05-31_Addendum_MBoisjoly_ready.csv", fileEncoding = "UTF-8", row.names = F)

