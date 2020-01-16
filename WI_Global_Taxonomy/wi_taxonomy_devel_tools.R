# wi_taxonomy_devel_tools.R
# Purpose- This script is for development purposes only. After we have tested and improved these concepts we will move them to the WI_Taxonomy. R scxript
# Things that this script can do:

# 1. Coming Soon: Your Taxomonic Data: Analyze your taxonomic data to look for simple mistakes that frequently happen with
#    scientific and common names.
# 2. Coming Soon: Identify differeces between your scientific taxonomy and the WIGT.
# 3. For consideration: Common names - If you used common names to identify animals, use this tool to find the correct scientific names.
# 4. For consideration: Consider building a way for the data provider to load their entire datasets and then do global find
#    and replaces from their taxonomy to WIGT.
# 5. For consideration: Use redlist.R project to provide synonnyms to data providers. 

########################
# Clear your R environmnet
rm(list = ls())
# Use the following libraries. 
library(jsonlite)
library(dplyr)
library(stringr)

########################
# 1. Your Taxonomic Data
#  Analyze your taxonomic data to look for simple mistakes that frequently happen with
#  scientific names.

# Load a file that has all the names you have used to identify animals in your images or video
#your_taxa <- read.csv("../team_data_migration/team_taxa_match_output.csv",colClasses = "character",strip.white = TRUE,na.strings="") # Replace with the path to your file and your data file name.
#your_taxa <- read.csv("wcs_taxonomy_map_20190911.csv",colClasses = "character",strip.white = TRUE,na.strings="")
#your_taxa <- read.csv("WWF cleaned taxonomy - wwf_tax.csv",colClasses = "character",strip.white = TRUE,na.strings="")

# To Do: Add in some search tools to look for spelling mistakes

########################
# 2. Your Taxonomic Data
# your_taxa must have at least  two columns for Genus and Species. If they are in one column then you can split them apart into two columns. Most datasets have taxonomy for higher taxons (ex. Birds equals Class{Aves}). 
# Some datasets may also have names for things that are not animals (ex. car). Wildlife Insights uses 6 attributes (columns in a datafile) to describe anything that can be observed
# in an image. These are: class, order, family, genus, species, common_name.  Together these make up the compound primary key (i.e. they make them unique) in the WI database. 
#your_taxa$class <- your_taxa$wi_class
#your_taxa$order <- your_taxa$wi_order
#your_taxa$family <- your_taxa$wi_family
#your_taxa$genus<- your_taxa$wi_genus
#your_taxa$species <- your_taxa$wi_species
#your_taxa$commonNameEnglish <- your_taxa$wi_common_name
#your_taxa$uniqueIdentifier <- your_taxa$wi_taxon_id

# Clean NAs
#your_taxa <- your_taxa %>% replace(., is.na(.), "")
# Double check to make sure this is a unique list or if not, make it a unique list of taxonomic names. 
# The columns names must also match between your dataset and the WIGT dataset. 
#your_unique_taxa <- distinct(your_taxa,class,order,family,genus,species,commonNameEnglish,uniqueIdentifier) 
#your_unique_taxa$taxon <- paste(your_unique_taxa$class,your_unique_taxa$order,your_unique_taxa$family,your_unique_taxa$genus,your_unique_taxa$species,your_unique_taxa$commonNameEnglish,your_unique_taxa$uniqueIdentifier,sep="-")
# Make a unique key for easy comparison
#wi_taxa_data$taxon <- paste(wi_taxa_data$class,wi_taxa_data$order,wi_taxa_data$family,wi_taxa_data$genus,wi_taxa_data$species,wi_taxa_data$commonNameEnglish,wi_taxa_data$uniqueIdentifier,sep="-")
#wi_taxa_data_new <- select(wi_taxa_data,class,order,family,genus,species,commonNameEnglish,uniqueIdentifier,taxon)
# Find records that don't match teh WI Taxonomy
#not_matching <- setdiff(your_unique_taxa,wi_taxa_data_new,by="taxon")

#if (nrow(not_matching) == 0) {
#  "Taxonomy looks great and maps into the Wildlife Insights Taxonomy"
#  write.csv(your_unique_taxa,file="final_taxonomy.csv",row.names = FALSE)
#} else {
#  paste("There are ",nrow(not_matching),"species that need to be mapped into the WI taxonomy")
#}


#clean_taxonmy <- select(your_unique_taxa$class

# Ways to chec
# out <- wi_taxa_data_new[which(not_matching$uniqueIdentifier[2] == wi_taxa_data$uniqueIdentifier),]
# write.csv(out,"out.csv",row.names = FALSE)
# 
# write.csv(not_matching,"notmatch.csv")
# team_taxa <- distinct(ct_data_final,taxon_join_gs)

########################
# 5. TBC

# Replace the columns in the next line with the columns that are unique names in your dataset. For example, if you identified
# all the way down to species then you can just use your genus and species column. If sometimes you could only identify to the 
# Family level, include the family column. If you used common names there is a good chance we won't find any chances but try it 
# nonetheless. 
# search_taxa <- c(your_taxa$family,your_taxa$genus,your_taxa$species)
# search_taxa <- str_remove_all(search_taxa, "Oppossum")
# search_taxa <- "virginiana"
# 
# 
# #d<- sapply(strsplit(search_taxa, '[, ]+'), function(x) toString(dQuote(x)))
# 
# keywords <-  search_taxa#your_unique_taxa # r <- c("mammalia", "boliviensis")
# t <- wi_taxa[Reduce(`|`,lapply(wi_taxa, `%in%`, keywords)),]
# 
# # Match scientific names with common names
# species_unique <- as.data.frame(unique(ss_df$name))