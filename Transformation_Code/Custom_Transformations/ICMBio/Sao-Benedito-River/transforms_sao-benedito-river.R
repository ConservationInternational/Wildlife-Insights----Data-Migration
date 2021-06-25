
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

dep <- read.csv("/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Sao-Benedito-River/deployments.csv",1)
img <- read.csv("/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Sao-Benedito-River/images.csv",1)
cam <- read.csv("/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Sao-Benedito-River/cameras.csv",1)
prj <- read.csv("/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Sao-Benedito-River/projects.csv",1)

prj$project_sensor_method = "Sensor Detection"
prj$project_bait_type = "None"
prj$project_name = "Sao-Benedito-River"
prj$project_short_name = "Sao-Benedito-River"

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
dep[dep$deployment_id=="CT-SBR-1-22 2017-04-22","latitude"] = -9.063557
dep[dep$deployment_id=="CT-SBR-1-22 2017-04-22","longitude"] = -56.529719

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
dep =dep[dep$deployment_id %in% img$deployment_id,]

dep=dep[dep$deployment_id!="CT-SBR-1-05 2017-04-19",]
dep=dep[dep$deployment_id!="CT-SBR-1-08 2017-04-19",]
dep=dep[dep$deployment_id!="CT-SBR-1-11 2017-04-21",]
dep=dep[dep$deployment_id!="CT-SBR-1-27 2017-04-22",]

img=img[img$deployment_id!="CT-SBR-1-05 2017-04-19",]
img=img[img$deployment_id!="CT-SBR-1-08 2017-04-19",]
img=img[img$deployment_id!="CT-SBR-1-11 2017-04-21",]
img=img[img$deployment_id!="CT-SBR-1-27 2017-04-22",]
img=img[img$location!="gs://icmbio/Sao-Benedito-River/CT-SBR-1-21/06150362.JPG",]

write.table(dep,file="/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Sao-Benedito-River/output/deployments.csv", row.names = FALSE, sep=",")
write.table(img,file="/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Sao-Benedito-River/output/images.csv", row.names = FALSE, sep=",")
write.table(cam,file="/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Sao-Benedito-River/output/cameras.csv", row.names = FALSE, sep=",")
write.table(prj,file="/Users/anthonyngo/Documents/Wildlife_Insights/ICMBio/Sao-Benedito-River/output/projects.csv", row.names = FALSE, sep=",")
