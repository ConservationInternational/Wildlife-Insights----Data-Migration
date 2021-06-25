
# Importing Libraries
rm(list = ls())
# Load libraries
library(dplyr)
library(readxl)
library(tidyverse)
library(googlesheets)
library(lubridate)

######
# Set the following variables to the appropriate values for your project
# See README.md in the Sanderson directory for descriptions of each variable


wi_taxonomy = read.csv("/Users/anthonyngo/Documents/Wildlife_Insights/Wildlife-Insights----Data-Migration/WI_Global_Taxonomy/WI_Global_Taxonomy.csv")

dep <- read.csv("/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Jamari/deployments.csv",1)
img <- read.csv("/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Jamari/images.csv",1)
cam <- read.csv("/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Jamari/cameras.csv",1)
prj <- read.csv("/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Jamari/projects.csv",1)

prj$project_sensor_method = "Sensor Detection"
prj$project_bait_type = "None"

cam[cam$camera_id == "", "camera_id"] = "NULL"

dep$start_date = paste(dep$start_date, "00:00:00", sep=" ")
dep$end_date = paste(dep$end_date, "00:00:00", sep=" ")

dep$subproject_name = ""
dep$subproject_design = ""
dep$event_name = ""
dep$event_description = ""
dep$event_type = ""
dep$bait_description = ""
dep$feature_type = "None"
dep$feature_type_methodology=""
dep$quiet_period=0
dep$height_other=""
dep$orientation_other=""
dep$recorded_by=""

dep[dep$camera_id=="", "camera_id"]="NULL"
dep[dep$camera_id == "00000000", "camera_id"] = "0"
dep[dep$camera_id == "000000000", "camera_id"] = "0"

img[img$wi_taxon_id=="527c9d88-4d7d-4406-add9-c0a823697926",c("wi_taxon_id", "class", "genus", "family", "order", "species", "common_name")]=
  wi_taxonomy[wi_taxonomy$uniqueIdentifier == "2cfa3934-1e52-4568-a98e-cfc40ad7c91f", c("uniqueIdentifier", "class", "genus", "family", "order", "species", "commonNameEnglish")]

img[is.na(img$uncertainty), "uncertainty"]<-""
img[is.na(img$number_of_objects), "number_of_objects"]<-""
img[is.na(img$highlighted), "highlighted"]<-""
img[is.na(img$age), "age"]<-""
img[is.na(img$sex), "sex"]<-""
img[is.na(img$animal_recognizable), "animal_recognizable"]<-""
img[is.na(img$individual_id), "individual_id"]<-""
img[is.na(img$individual_animal_notes), "individual_animal_notes"]<-""
img[is.na(img$markings), "markings"]<-""
img[img$number_of_objects == "", "number_of_objects"] <- 1
img[img$identified_by == "", "identified_by"] <- "Elildo Carvalho Jr"

img$location <- paste(substr(img$location, 0, 19),substr(img$timestamp, 0, 4), substr(img$location, 19, 100), sep="" )

img[img$identified_by == "C\xedntia Lopes", "identified_by"] = "Cintia Lopes"

img = img[!grepl("NA", img$location),]
img$location = gsub("\t", "", img$location)

dep =dep[dep$deployment_id %in% img$deployment_id,]

write.table(dep,file="/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Jamari/output/deployments.csv", row.names = FALSE, sep=",")
write.table(img,file="/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Jamari/output/images.csv", row.names = FALSE, sep=",")
write.table(cam,file="/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Jamari/output/cameras.csv", row.names = FALSE, sep=",")
write.table(prj,file="/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Jamari/output/projects.csv", row.names = FALSE, sep=",")
