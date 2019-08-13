# WI_Taxonomy.R
# Purpose- This script is meant to help a Wildlife Insights data provider map the taxonomy
# they used in their project to the taxonomy used by Wildlife Insights. Wildlife Insights (WI) 
# refers to their taxonomy as the Wildlife Inisghts Global Taxonomy (WIGT). All data being uploaded 
# into Wildlife Insights must map into the WIGT. Without doing this there will be no practival way 
# to perform analytics across WI projects and initiatives. If you have questions on your taxonomy,
# how to map them into the WIGT, questions on this script or anything else please email info@wildlifeinsights.org.
#
# Things that this script can do:
# 1. WIGT: Import and share the Wildlife Insights Global Taxonomy
# 2. Your Taxomonic Data: Analyze your taxonomic data to look for simple mistakes that frequently happen with
#    scientific and common names.
# 3. Identify differeces between your scientific taxonomy and the WIGT.
# 4. For consideration - Common names - If you used common names to identify animals, use this tool to find the correct scientific names.
# 4. For consideration - Consider building a way for the data provider to load their entire datasets and then do global find
#    and replaces from their taxonomy to WIGT.
# 5. For consideration - Use rredlist.R project to provide synonnyms to data providers. 

########################
# Clear your R environmnet
rm(list = ls())
# Use the following libraries. 
library(jsonlite)
library(dplyr)
library(stringr)
########################
# 1. Import the Wildife Insights Global Taxonomy dataset.
wi_taxa <- fromJSON("https://staging.api.wildlifeinsights.org/api/v1/taxonomy?fields=class,order,family,genus,species,commonNameEnglish&taxon_level=species&page[size]=30000")
wi_taxa_data <- wi_taxa$data
# Write out a .csv file for anyone wanting to look at this in Excel. Feel free to inspect this file and use it 
# however you need to find what matches the taxonomy used in your datasets. We have some tools below to help do this but it is up to 
# you. You can also refernece: https://www.iucnredlist.org/ 
write.csv(wi_taxa_data,"WI_Taxonomy.csv",row.names = FALSE)


########################
# 2. Your Taxonomic Data
#  Analyze your taxonomic data to look for simple mistakes that frequently happen with
#  scientific names.

#Load a file that has all the names you have used to identify animals in your images or video
your_taxa <- read.csv("wi_datafiles/your_taxonomy_file_example.csv",colClasses = "character",strip.white = TRUE,na.strings="") # Replace with the path to your file and your data file name.

# Add in some search tools to look for spelling mistakes

########################
# 3. Your Taxonomic Data
# your_taxa needs to have 5 columns: class, order, family, genus, species. If you do not have all of these
# you can create empty columns like the example below. Or if you do have thise columsn just assign them to the dataframe:
# your_taxa$class <- NA
# your_taxa$order <- NA
# your_taxa$family <- NA
# your_taxa$genus<- NA
# your_taxa$species <- NA
# Double check to make sure this is a unique list or if not, make it a unique list of taxonomic names. 
# Replace the column names to match your column names
your_unique_taxa <- distinct(your_taxa,class,order,family,genus,species,.keep_all = TRUE) 

wigt_taxa <- select(wi_taxa_data,class,order,family,genus,species)
# Find records that don't match teh WI Taxonomy
not_matching <- setdiff(your_unique_taxa,new_wigt)

########################
# 4. TBC

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