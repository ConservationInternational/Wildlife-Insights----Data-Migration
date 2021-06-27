# CDFW_data_migration.R Anthony Ngo 01/2021
# Purpose: California Department of Fish and Wildlife to 
# Wildlife Insights Data Migration Tool

######
# Clear workspace
rm(list=ls())
# Load Libraries
library(dplyr)
library(readxl)
library(openxlsx)
library(googlesheets)
library(jsonlite)
library(stringr)
library(lubridate)

source('Transformation_Code/Generic_Functions/wi_functions.R')

# Path of data in need of reformatting
data15_path <- "/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/MCDA/MCDA_2015_ImageData.xlsx"
data16_path <- "/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/MCDA/MCDA_2016_ImageData.xlsx"

# Path of data in BU formatting
cam_path <- "/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/MCDA/camera.csv"
dep_path <- "/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/MCDA/deployment.csv"
prj_path <- "/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/MCDA/project.csv"

prj_id = "MCDA"
prj_bucket <- "MCDA"

#Loading the data in

## Loading in the image file data
data15 <- read_excel(data15_path, sheet=1)
data16 <- read_excel(data16_path, sheet=1)

data15$year <- "2015"
data16$year <- "2016"

## Loading in the Event-Species mappings\
key15 <- read_excel(data15_path, sheet=4)
key16 <- read_excel(data16_path, sheet=4)

## Loading in the Batch upload files
cam <- read.csv(cam_path)
dep <- read.csv(dep_path)
prj <- read.csv(prj_path)

## Loading in the Wildlife Insights Taxonomical key
wi_taxonomy = read.csv("./WI_Global_Taxonomy/WI_Global_Taxonomy.csv")


#Creating WI key matching
key <- rbind(key15, key16)

names(key) <- c("Event", "commonNameEnglish")
key$notes <- ""
key$splitNotes <- str_split(key$notes, " ")
key$genus <- sapply(key$splitNotes, `[[`, 1)
key$species <- sapply(key$splitNotes, tail, 1)
key <- key[!is.na(key$notes),]

#Gathering unique identifiers
wi_key <- left_join(key, wi_taxonomy[c("genus", "species", "uniqueIdentifier")], by=c("genus", "species"), all.x = TRUE)
wi_key <- wi_key[c("Event", "uniqueIdentifier")]
wi_key <- rbind(wi_key, read.csv("~/Documents/Wildlife_Insights/CDFW/CDFW_taxonomy/cdfw_wi_pairings.csv"))

#Finalizing Wi Key
wi_key <- left_join(wi_key, wi_taxonomy, by="uniqueIdentifier", all.x = TRUE)
wi_key <- wi_key[!is.na(wi_key$uniqueIdentifier),]
# Removing duplicate humans
wi_key <- wi_key[!grepl("Human-", wi_key$commonNameEnglish),]
# Removing duplicate keys
wi_key <- unique(wi_key)
rm( key15, key16, wi_taxonomy)

#Putting together image data
data15$Reviewer <- "Fust Boswell"
data16$Reviewer <- "Marin Fust"


# names(data17)[names(data17) == "...3"] <- "Subfolder"
data16$...10 <- ""
data <- rbind( data15, data16)
data$Reference <-gsub("&", ",", data$Reference)
rm(data15, data16)

######
# Project Batch Upload Template: Load in the project batch upload template and fill it out.

prj_bu <- prj
prj_bu$project_id <- prj_id
prj_bu$initiative_id <- 1
prj_bu$project_bait_type <- "None"
prj_bu$project_blank_images <- "Some"
prj_bu$project_species <- "Individual"
prj_bu$project_species_individual <- "627c919c-29bc-439b-acde-62b3cd31f8a8"

rm(prj)
######
# Camera Batch Upload Template: Fill in the information relatd to the cameras/sensors used in your project
# First need to get the number of cameras used in the project

cam_bu <- cam
cam_bu$project_id <- prj_id

cam_bu <- cam_bu[cam_bu$camera_id!="",]
rm(cam)
######
# Deployment Batch Upload Template: Fill in the information related to each deployment. A deployment is a sensor 
# observing wildlife for some amount of time in a specific location. 

dep_bu <- dep
dep_bu$project_id <- prj_id
dep_bu$start_date <- paste(paste(lapply(str_split(dep$start_date, "/"), `[[`, 3),
                                 str_pad(lapply(str_split(dep$start_date, "/"), `[[`, 1), 2, pad="0"),
                                 str_pad(lapply(str_split(dep$start_date, "/"), `[[`, 2), 2, pad="0"), sep="-"), "00:00:00", sep=" ")
dep_bu$end_date <- paste(paste(lapply(str_split(dep$end_date, "/"), `[[`, 3),
                               str_pad(lapply(str_split(dep$end_date, "/"), `[[`, 1), 2, pad="0"),
                               str_pad(lapply(str_split(dep$end_date, "/"), `[[`, 2), 2, pad="0"), sep="-"), "00:00:00", sep=" ")
dep_bu[dep_bu$sensor_height=="Other ","sensor_height"] <- "Other"
dep_bu[dep_bu$camera_functioning=="Memory Card","camera_functioning"] <- "Camera Functioning"
rm(dep)

######
# Image Batch Upload Template: Fill in the information related to each image

img_raw <- data[!is.na(data$Reference),]
img_raw$Reference <- gsub(". ", "-",img_raw$Reference)

#Expanding Data for individual images
# img_raw$Reference <- sub(",$", "", img_raw$Reference)
img_raw$Reference <- sub("-$", "", img_raw$Reference)

indices <- rep(1:nrow(img_raw), str_count(img_raw$Reference, ",")+1)

img_raw$Reference <- str_split(img_raw$Reference, ",")

unlisted_ref <- unlist(img_raw$Reference)
img_raw <- img_raw[indices, ]

img_raw$Reference <- unlisted_ref

img_raw$listed_references <- str_split(img_raw$Reference, "-")

img_raw$first <- lapply(img_raw$listed_references, `[[`, 1)
img_raw$last <- lapply(img_raw$listed_references, tail, 1)
img_raw <- img_raw[!is.na(as.numeric(img_raw$last)),]
img_raw$listed_references <- Map(":",
                                 unlist(as.numeric(img_raw$first)),
                                 unlist(as.numeric(img_raw$last)))

unlisted_ref <- unlist(img_raw$listed_references)

indices <- rep(1:nrow(img_raw), lengths(img_raw$listed_references))
img_raw <- img_raw[indices, ]
img_raw$Reference <- unlisted_ref

# Constructing Missing Bucket Level
trueLocations <- read.csv("~/Documents/Wildlife_Insights/CDFW/deerimagefiles/MCDA/trueLocations.csv")
trueLocations15 <- trueLocations[grepl("gs://cadfw/Deer_Program/MCDA/MCDA_2015/....",trueLocations$locations),]
trueLocations15$site_station <- lapply(str_split(trueLocations15$locations, "/"), `[[`, 7)
trueLocations15$subfolder <- lapply(str_split(trueLocations15$locations, "/"), `[[`, 8)
trueLocations15$subfolder1 <- trueLocations15$subfolder
subfolders <- unique(trueLocations15[trueLocations15$subfolder1!=":",c("site_station", "subfolder1", "subfolder")])
subfolders$date <- paste(substr(subfolders$subfolder1, 9, 12),
                         substr(subfolders$subfolder1, 5, 6),
                         substr(subfolders$subfolder1, 7, 8), sep="-")
ir15 <- img_raw[img_raw$year=="2015",]
ir15$site_station <- paste(ir15$Site,ir15$Station, sep="_")
ir15 <- merge(ir15, subfolders, by="site_station")
ir15 <- ir15[ir15$Date < ir15$date,]
ir15 <- ir15[order(ir15$date),]
ir15 <- ir15[!duplicated(ir15[,c("site_station","Site","Station","Date","Event","Class" ,           
                                          "Count","Reference","Aim","Notes","...10","year",            
                                          "Reviewer","listed_references","first","last")]),]

ir15$locations <- paste("gs://cadfw/Deer_Program",
                          prj_id, paste("MCDA_", ir15$year, sep=""),
                          ir15$site_station,ir15$subfolder,
                          paste("IMG_",str_pad(ir15$Reference, 4, pad="0"),".JPG", sep=""), sep="/")

ir16 <- img_raw[img_raw$year=="2016",]
trueLocations16 <- trueLocations[grepl("gs://cadfw/Deer_Program/MCDA/MCDA_2016/",trueLocations$locations)&
                                   grepl(".JPG",trueLocations$locations),]
trueLocations16$Site <- lapply(str_split(trueLocations16$locations, "/"), `[[`, 7)
trueLocations16$Station <- lapply(str_split(trueLocations16$locations, "/"), `[[`, 8)
trueLocations16$Reference <- as.numeric(gsub(".JPG", "",
                                             gsub("IMG_", "",
                                                  lapply(str_split(trueLocations16$locations, "/"), tail, 1))))
trueLocations16$subfolder <- gsub("IMG_.....JPG|gs://cadfw/Deer_Program/MCDA/MCDA_2016/../.","",trueLocations16$locations)
trueLocations16$date_raw <- gsub("[a-zA-Z]|/","",trueLocations16$subfolder)
trueLocations16$date <- paste("2016",
                         substr(trueLocations16$date_raw, 1,2),
                         substr(trueLocations16$date_raw, 3,4), sep="-")
trueLocations16[trueLocations16$date=="2016-92-11", "date"] <- "2016-09-21"
trueLocations16[trueLocations16$date=="2016-92-81", "date"] <- "2016-09-28"

count_16 <- nrow(img_raw[img_raw$year=="2016",])

ir16_loc <- merge(ir16, trueLocations16[,c("locations", "date","Site", "Station", "Reference", "subfolder")], by=c("Site", "Station", "Reference"))

ir16_loc <- ir16_loc[order(ir16_loc$date),]
ir16_loc <- ir16_loc[!duplicated(ir16_loc[,c("Site","Station","Reference",
                                             "Date","Event","Class","Count",
                                             "Aim","Notes","...10","year",
                                             "Reviewer","listed_references","first","last")]),]


img_raw <- rbind(ir15[,c("Site","Station","Reference","Date","Event","Class",
                         "Count","Aim","Notes","...10","year","Reviewer",
                         "listed_references","first","last","locations","date", "subfolder")]
                 , ir16_loc)
rm(ir15, ir16,ir16_loc, trueLocations15, trueLocations16)
img_raw$location <- gsub("00NONE/", "", img_raw$location)
img_raw$location <- gsub("NONE/", "", img_raw$location)

img_raw$dep_id <- paste(paste(img_raw$Site, img_raw$Station, sep=""), img_raw$year, sep="-")

# Mapping WI Taxon values
img_raw <- left_join(img_raw, wi_key, by="Event", all.x = TRUE)

# Adding Timestamps----
img_raw$createDate <- paste(img_raw$Date, "00:00:00", sep=" ")

img_raw[is.na(img_raw$Count),"Count"] <- 1
img_raw[as.numeric(img_raw$Count) > 50,"Count"] <- 50

#Info regarding Class Codes
img_raw[img_raw$Class=="B1" & !is.na(img_raw$Class),"SEX"] <-  "Male"
img_raw[img_raw$Class=="B2" & !is.na(img_raw$Class),"SEX"] <-  "Male"
img_raw[img_raw$Class=="B3" & !is.na(img_raw$Class),"SEX"] <-  "Male"
img_raw[img_raw$Class=="B4" & !is.na(img_raw$Class),"SEX"] <-  "Male"
img_raw[img_raw$Class=="UB" & !is.na(img_raw$Class),"SEX"] <- "Male"
img_raw[img_raw$Class=="D" & !is.na(img_raw$Class),"SEX"] <-  "Female"
img_raw[is.na(img_raw$SEX),"SEX"] <-  ""

img_raw[img_raw$Class=="B1" & !is.na(img_raw$Class),"AGE"] <-  "Adult"
img_raw[img_raw$Class=="B2" & !is.na(img_raw$Class),"AGE"] <-  "Adult"
img_raw[img_raw$Class=="B3" & !is.na(img_raw$Class),"AGE"] <-  "Adult"
img_raw[img_raw$Class=="B4" & !is.na(img_raw$Class),"AGE"] <-  "Adult"
img_raw[img_raw$Class=="UA" & !is.na(img_raw$Class),"AGE"] <- "Adult"
img_raw[img_raw$Class=="D" & !is.na(img_raw$Class),"AGE"] <-  "Adult"
img_raw[img_raw$Class=="UA" & !is.na(img_raw$Class),"AGE"] <- "Adult"
img_raw[img_raw$Class=="F" & !is.na(img_raw$Class),"AGE"] <- "Juvenile"
img_raw[is.na(img_raw$AGE),"AGE"] <- ""

img_raw <- img_raw[img_raw$Event!="NF",]

# Creating Batch Upload File ----
img_count <- nrow(img_raw)

img_bu <- wi_batch_function("Image", img_count)
img_bu$project_id <- prj_id
img_bu$deployment_id <- img_raw$dep_id
img_bu$image_id <- paste(img_raw$Site, img_raw$Station, img_raw$subfolder, img_raw$Reference, sep="-")
img_bu$location <- img_raw$location
img_bu$identified_by <- img_raw$Reviewer

img_bu$wi_taxon_id <- img_raw$uniqueIdentifier
img_bu$class <- img_raw$class
img_bu$order <- img_raw$order
img_bu$family <- img_raw$family
img_bu$genus <- img_raw$genus
img_bu$species <- img_raw$species
img_bu$common_name <- img_raw$commonNameEnglish
img_bu$uncertainty <- ""
img_bu$timestamp <- img_raw$createDate
img_bu$number_of_objects <- img_raw$Count
img_bu$highlighted <- ""
img_bu$age <- img_raw$AGE
img_bu$sex <- img_raw$SEX
img_bu$animal_recognizable <- ""
img_bu$individual_id <- ""
img_bu$individual_animal_notes <- img_raw$Notes
img_bu$markings <- img_raw$Notes
img_bu$external_sequence_id <- ""
img_bu$sequence_start_time <- ""
rm(img_raw, indices, unlisted_ref, img_count, timestamps)
write.table(cam_bu,file="/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/MCDA/output/cameras.csv", row.names = FALSE, sep=",")
write.table(dep_bu,file="/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/MCDA/output/deployments.csv", row.names = FALSE, sep=",")
write.table(img_bu,file="/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/MCDA/output/images.csv", row.names = FALSE, sep=",")
write.table(prj_bu,file="/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/MCDA/output/projects.csv", row.names = FALSE, sep=",")

