# WI_Taxonomy.R
# Purpose- This script will query the Wildlife Insights API and make a copy of hte full
# Wildlife Inisghts Global Taxonomy (WTGT).  All data being uploaded 
# into Wildlife Insights must map into the WIGT. Without doing this there will be no practival way 
# to perform analytics across WI projects and initiatives. 

########################
# Clear your R environmnet
rm(list = ls())
# Use the following libraries. 
library(jsonlite)
########################
# 1. Import the Wildife Insights Global Taxonomy dataset.
wi_taxa <- fromJSON("https://api.wildlifeinsights.org/api/v1/taxonomy?fields=class,order,family,genus,species,authority,taxonomyType,uniqueIdentifier,commonNameEnglish&page[size]=30000")
wi_taxa_data <- wi_taxa$data
wi_taxa_data <- wi_taxa_data %>% replace(., is.na(.), "")
# Write out a .csv file for anyone wanting to look at this in Excel. Feel free to inspect this file and use it 
# however you need to find what matches the taxonomy used in your datasets.
# Check out the data
View(wi_taxa_data)
# Write a.csv file if you want to look at it in Excel or a text editor. 
write.csv(wi_taxa_data,"WI_Global_Taxonomy/WI_Global_Taxonomy.csv",row.names = FALSE)
