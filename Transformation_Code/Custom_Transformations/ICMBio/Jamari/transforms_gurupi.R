
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

dep <- read.csv("/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Gurupi/deployments.csv",1)
img <- read.csv("/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Gurupi/images.csv",1)
cam <- read.csv("/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Gurupi/cameras.csv",1)
prj <- read.csv("/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Gurupi/projects.csv",1)

prj$project_sensor_method = "Sensor Detection"
prj$project_bait_type = "None"
prj$project_name = "Gurupi_1"
prj$project_short_name = "Gurupi_1"

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

dep[dep$longitude=="-46.729", "longitude"]="-46.72900"

dep[dep$camera_id=="", "camera_id"]="NULL"

img[!grepl(":", img$timestamp), "timestamp"] = gsub("NA", "00:00:00", img[!grepl(":", img$timestamp), "timestamp"])
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
#substr(img$timestamp, 0, 4)
#substr(img$location, 0, 19)
#substr(img$location, 19, 100)
img$location <- paste(substr(img$location, 0, 19),substr(img$timestamp, 0, 4), substr(img$location, 19, 100), sep="" )

dep =dep[dep$deployment_id %in% img$deployment_id,]

write.table(dep,file="/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Gurupi/output/deployments.csv", row.names = FALSE, sep=",")
write.table(img,file="/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Gurupi/output/images.csv", row.names = FALSE, sep=",")
write.table(cam,file="/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Gurupi/output/cameras.csv", row.names = FALSE, sep=",")
write.table(prj,file="/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Gurupi/output/projects.csv", row.names = FALSE, sep=",")
