
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

dep <- read.csv("/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Maraca/deployments.csv",1)
img <- read.csv("/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Maraca/images.csv",1)
cam <- read.csv("/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Maraca/cameras.csv",1)
prj <- read.csv("/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Maraca/projects.csv",1)

prj$project_sensor_method = "Sensor Detection"
prj$project_bait_type = "None"

cam[cam$camera_id == "NA", "camera_id"] = "NULL"
cam[nrow(cam) + 1,] = c("EEM","8988", "Bushnell", "Trophy Cam HD", "8988", "2016")
cam[nrow(cam) + 1,] = c("EEM","Unknown", "Bushnell", "Trophy Cam HD", "Unknown", "2016")

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


dep[is.na(dep$camera_id),"camera_id"]="Unknown"
dep[dep$latitude=="3.396", "latitude"]="3.39600"
dep[dep$longitude=="61.647","longitude"]="61.64700"
dep[dep$longitude=="-61.647","longitude"]="-61.64700"

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
img[img$identified_by == "V\xe2nia Oliveira", "identified_by"] <- "Vania Oliveira"
img$location <- paste(substr(img$location, 0, 19),"2018", substr(img$location, 19, 100), sep="" )

dep =dep[dep$deployment_id %in% img$deployment_id,]

write.table(dep,file="/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Maraca/output/deployments.csv", row.names = FALSE, sep=",")
write.table(img,file="/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Maraca/output/images.csv", row.names = FALSE, sep=",")
write.table(cam,file="/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Maraca/output/cameras.csv", row.names = FALSE, sep=",")
write.table(prj,file="/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Maraca/output/projects.csv", row.names = FALSE, sep=",")
