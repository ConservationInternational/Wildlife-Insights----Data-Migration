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
data17_path <- "/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/CCDA/CCDA_2017_ImageData.xlsx"
data18_path <- "/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/CCDA/CCDA_2018_ImageData.xlsx"

# Path of data in BU formatting
cam_path <- "/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/CCDA/cameras.csv"
dep_path <- "/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/CCDA/deployments.csv"
prj_path <- "/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/CCDA/projects.csv"

prj_id = "CCDA"
prj_bucket <- "CCDA"

#Loading the data in

## Loading in the image file data
data17 <- read_excel(data17_path, sheet=3)
data18 <- read_excel(data18_path, sheet=3)

data17$year <- "2017"
data18$year <- "2018"

## Loading in the Event-Species mappings
key17 <- read_excel(data17_path, sheet=length(getSheetNames(data17_path))-1)
key18 <- read_excel(data18_path, sheet=length(getSheetNames(data18_path))-1)

## Loading in the Batch upload files
cam <- read.csv(cam_path)
dep <- read.csv(dep_path)
prj <- read.csv(prj_path)

## Loading in the Wildlife Insights Taxonomical key
wi_taxonomy = read.csv("./WI_Global_Taxonomy/WI_Global_Taxonomy.csv")

#Creating WI key matching
key <- rbind(key17[, 1:3], key18)

names(key) <- c("Event", "commonNameEnglish", "notes")
key$splitNotes <- str_split(key$notes, " ")
key$genus <- sapply(key$splitNotes, `[[`, 1)
key$species <- sapply(key$splitNotes, tail, 1)
key <- key[!is.na(key$notes),]

#Gathering unique identifiers
wi_key <- left_join(key, wi_taxonomy[c("genus", "species", "uniqueIdentifier")], by=c("genus", "species"), all.x = TRUE)
#Manually adding unique identifiers

wi_key <- wi_key[c("Event", "uniqueIdentifier")]
wi_key <- rbind(wi_key, read.csv("~/Documents/Wildlife_Insights/CDFW/CDFW_taxonomy/cdfw_wi_pairings.csv"))
#Finalizing Wi Key
wi_key <- left_join(wi_key, wi_taxonomy, by="uniqueIdentifier", all.x = TRUE)
wi_key <- wi_key[wi_key$commonNameEnglish!="Red Deer",]
wi_key <- wi_key[!is.na(wi_key$uniqueIdentifier),]
# Removing duplicate humans
wi_key <- wi_key[!grepl("Human-", wi_key$commonNameEnglish),]
# Removing duplicate keys
wi_key <- unique(wi_key)
rm(key17, key18, wi_taxonomy)
#Putting together image data
# data17 <- data17[,1:9]
data17$Reviewer <- "Fust-Trausch"
data18$Reviewer <- "Bullington"
data <- rbind(data17, data18)

rm(data17, data18)

######
# Project Batch Upload Template: Load in the project batch upload template and fill it out.

prj_bu <- prj
prj_bu$project_id <- prj_id
prj_bu$initiative_id <- 1
prj_bu$project_bait_type <- "None"
prj_bu$project_blank_images <- "No"
prj_bu$project_species <- "Individual"

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
dep_bu[dep_bu$deployment_id=="30586L-2017","deployment_id"] <- "30568L-2017"
dep_bu[dep_bu$deployment_id=="28936K-2017","start_date"]="2017-04-19 00:00:00"
dep_bu[dep_bu$deployment_id=="28936L-2017","start_date"]="2017-04-19 00:00:00"
rm(dep)

######
# Image Batch Upload Template: Fill in the information related to each image

img_raw <- data[!is.na(data$Reference),]

#Expanding Data for individual images
img_raw$Reference <- sub(",$", "", img_raw$Reference)
img_raw$Reference <- sub("-$", "", img_raw$Reference)

indices <- rep(1:nrow(img_raw), str_count(img_raw$Reference, ",")+1)

img_raw$Reference <- str_split(img_raw$Reference, ",")

unlisted_ref <- unlist(img_raw$Reference)
img_raw <- img_raw[indices, ]

img_raw$Reference <- unlisted_ref



img_raw[img_raw$Reference==" 1-390 IN SUBFOLDER 061417", "Subfolder"] <- "061417"
img_raw[img_raw$Reference==" 1-390 IN SUBFOLDER 061417", "Reference"] <- "1-390"

img_raw[img_raw$Reference==" 9883-", "Reference"] <- "9883"

img_raw$listed_references <- str_split(img_raw$Reference, "-")

img_raw$first <- lapply(img_raw$listed_references, `[[`, 1)
img_raw$last <- lapply(img_raw$listed_references, tail, 1)
img_raw$listed_references <- Map(":",
                                 unlist(as.numeric(img_raw$first)),
                                 unlist(as.numeric(img_raw$last)))

unlisted_ref <- unlist(img_raw$listed_references)

indices <- rep(1:nrow(img_raw), lengths(img_raw$listed_references))
img_raw <- img_raw[indices, ]
img_raw$Reference <- unlisted_ref

# Constructing Missing Columns

img_raw[img_raw$Subfolder=="NONE","Subfolder"] <- sub(";","",sub("SUBFOLDER ","",str_extract(img_raw[img_raw$Subfolder=="NONE",]$Notes, "SUBFOLDER [0-9]{5,}a?A?;?")))
img_raw[is.na(img_raw$Subfolder),"Subfolder"]="NONE"
img_raw[img_raw$Subfolder=="NONE","Subfolder"] <- sub(";","",sub("SUBFODLER ","",str_extract(img_raw[img_raw$Subfolder=="NONE",]$Notes, "SUBFODLER [0-9]{5,}a?A?;?")))
img_raw[is.na(img_raw$Subfolder),"Subfolder"]="NONE"
img_raw[img_raw$Subfolder=="080517A","Subfolder"] = "080517a"
img_raw$pSubfolder <-  str_pad(img_raw$Subfolder, 6, pad="0")


img_raw[img_raw$Site=="33393" & img_raw$Station=="K","Station"]="K/K"

img_raw$location <- paste("gs://cadfw/Deer_Program",
                          prj_id,
                          img_raw$Site,img_raw$Station, img_raw$pSubfolder,
                          paste("IMG_",str_pad(img_raw$Reference, 4, pad="0"),".JPG", sep=""), sep="/")
img_raw$location <- gsub("00NONE/", "", img_raw$location)

img_raw$dep_id <- paste(paste(img_raw$Site, img_raw$Station, sep=""), img_raw$year, sep="-")
img_raw[img_raw$dep_id=="33393K/K-2017","dep_id"] <- "33393K-2017"

# Mapping WI Taxon values
img_raw <- left_join(img_raw, wi_key, by="Event", all.x = TRUE)

# Adding Timestamps----
timestamps <- read.csv("~/Documents/Wildlife_Insights/CDFW/deerimagefiles/CCDA/CCDA_exifs.csv")
timestamps$location <- paste("gs://cadfw/Deer_Program",
                             gsub("\\./","",timestamps$SourceFile), sep="/")
 
img_raw <- merge(x = img_raw, y = timestamps, by = "location", all.x = TRUE)
img_raw <- img_raw[!is.na(img_raw$createDate),]

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

img_raw[is.na(img_raw$Notes),"Notes"] <- ""


# Creating Batch Upload File ----
img_count <- nrow(img_raw)

img_bu <- wi_batch_function("Image", img_count)
img_bu$project_id <- prj_id
img_bu$deployment_id <- img_raw$dep_id
img_bu$image_id <- gsub("/","-slash-",paste(img_raw$Site, img_raw$Station, img_raw$pSubfolder, img_raw$Reference, sep="-"))
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
# Removing unused deployments
dep_bu <- dep_bu[dep_bu$deployment_id %in% img_bu$deployment_id,]

rm(img_raw, indices, unlisted_ref, img_count, timestamps)
write.table(cam_bu,file="/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/CCDA/output/cameras.csv", row.names = FALSE, sep=",")
write.table(dep_bu,file="/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/CCDA/output/deployments.csv", row.names = FALSE, sep=",")
write.table(img_bu,file="/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/CCDA/output/images.csv", row.names = FALSE, sep=",")
write.table(prj_bu,file="/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/CCDA/output/projects.csv", row.names = FALSE, sep=",")

