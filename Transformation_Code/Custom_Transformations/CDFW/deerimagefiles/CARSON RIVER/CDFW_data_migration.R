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

data_path <- "/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/CARSON RIVER/CARSON RIVER DA 2017-2018_ImageData.xlsx"
cam_path <- "/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/CARSON RIVER/cameras.csv"
dep_path <- "/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/CARSON RIVER/deployments.csv"
prj_path <- "/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/CARSON RIVER/projects.csv"

prj_id = "CDFW"
prj_bucket <- "Carson River"

#Load the data in
data <- read_excel(data_path, sheet=1)
cam <- read.csv(cam_path)
dep <- read.csv(dep_path)
prj <- read.csv(prj_path)
key <- read_excel(data_path, sheet=length(getSheetNames(data_path))-1)
wi_taxonomy = read.csv("./WI_Global_Taxonomy/WI_Global_Taxonomy.csv")

#Creating WI key matching
names(key) <- c("Event", "commonNameEnglish", "notes")
key$splitNotes <- str_split(key$notes, " ")
key$genus <- sapply(key$splitNotes, `[[`, 1)
key$species <- sapply(key$splitNotes, tail, 1)
key <- key[!is.na(key$notes),]

# Specific edits
key[key$genus=="Otopermophilus", "genus"] <- "Otospermophilus"
key[key$genus=="Caliospermophilus", "genus"] <- "Callospermophilus"
key[key$genus=="Didelphus", "genus"] <- "Didelphis"
key[key$genus=="Canus", "genus"] <- "Canis"

key[key$species=="familiaris", "species"] <- "lupus familiaris"

#Gathering unique identifiers
wi_key <- left_join(key, wi_taxonomy[c("genus", "species", "uniqueIdentifier")], by=c("genus", "species"), all.x = TRUE)

#Manually adding unique identifiers
wi_key[wi_key$genus=="Leporidae", "uniqueIdentifier"] <- "6c09fa63-2acc-4915-a60b-bd8cee40aedb"
wi_key[wi_key$species=="sp", "uniqueIdentifier"] <- "9a5d6ef5-887d-4060-8ef8-b7e54a7303de"
wi_key[wi_key$species=="Neotoma", "uniqueIdentifier"] <- "3ff7d1c3-af2d-4b25-aa3f-6524b5f34957"
wi_key[wi_key$species=="Peromyscus", "uniqueIdentifier"] <- "25540311-3902-4d4d-b40c-c6dbb5bb2665"
wi_key[wi_key$species=="Rodentia", "uniqueIdentifier"] <- "90d950db-2106-4bd9-a4c1-777604c3eada"
wi_key[wi_key$species=="Syvilagus", "uniqueIdentifier"] <- "cacc63d7-b949-4731-abce-a403ba76ee34"
wi_key[wi_key$species=="Tamias", "uniqueIdentifier"] <- "8a9cc0e5-2fe9-411a-a4f3-982f56a1e68a"

wi_key[nrow(wi_key) + 1,] = list("UNID",NA,NA,NA,NA,NA,"1f689929-883d-4dae-958c-3d57ab5b6c16")
wi_key[nrow(wi_key) + 1,] = list("VEHICLE",NA,NA,NA,NA,NA,"1a6d048a-28da-45bb-845d-a14cc5b7d61a")
wi_key[nrow(wi_key) + 1,] = list("UNBIRD",NA,NA,NA,NA,NA,"b1352069-a39c-4a84-a949-60044271c0c1")
wi_key[nrow(wi_key) + 1,] = list("CATTLE",NA,NA,NA,NA,NA,"aca65aaa-8c6d-4b69-94de-842b08b13bd6")
wi_key[nrow(wi_key) + 1,] = list("DOMCAT",NA,NA,NA,NA,NA,"9212982e-8a58-4775-a6ac-e9a43110d8f5")
wi_key[nrow(wi_key) + 1,] = list("HORSE",NA,NA,NA,NA,NA,"5109acb4-e503-4147-a175-a3c6aa71f1e3")
wi_key[nrow(wi_key) + 1,] = list("UNCANID",NA,NA,NA,NA,NA,"3184697f-51ad-4608-9a28-9edb5500159c")
wi_key[nrow(wi_key) + 1,] = list("DOMSHE",NA,NA,NA,NA,NA,"0de8422e-f59d-4802-9e93-ab8559e43e55")
wi_key[nrow(wi_key) + 1,] = list("BKBMAG",NA,NA,NA,NA,NA,"f6360527-6dfb-4cfa-890d-a522868ce416")
wi_key[nrow(wi_key) + 1,] = list("WESJAY",NA,NA,NA,NA,NA,"f76dea54-8d1d-4483-846b-a5c47ea7d4eb")
wi_key[nrow(wi_key) + 1,] = list("STEJAY",NA,NA,NA,NA,NA,"68b01aa1-dfc1-46a6-bcac-87767647ad17")
wi_key[nrow(wi_key) + 1,] = list("CALQUA",NA,NA,NA,NA,NA,"daf972d0-b038-4d10-8862-01d0e590e551")
wi_key[nrow(wi_key) + 1,] = list("MOUQUA",NA,NA,NA,NA,NA,"5ff8c8fd-372e-4bfb-8ca2-18e33780c797")
wi_key[nrow(wi_key) + 1,] = list("AMEROB",NA,NA,NA,NA,NA,"23140944-2bd7-46ce-819a-c26508c53d62")
wi_key[nrow(wi_key) + 1,] = list("UNBUTTERFLY",NA,NA,NA,NA,NA,"4a7126ec-2b0b-426d-bafd-356219eb487a")


#Finalizing Wi Key
wi_key <- left_join(wi_key[c("Event", "uniqueIdentifier")], wi_taxonomy, by="uniqueIdentifier", all.x = TRUE)

# Removing duplicate humans
wi_key <- wi_key[!grepl("Human-", wi_key$commonNameEnglish),]

# Rename the columns
column_names <- data[data[,1]=="Site",]
colnames(data) <- column_names
data <- data[data[,1]!="Site",]

#Convert XLSX dates to R standard date format
data$Date=convertToDate(data$Date)

rm(column_names)
######
# Project Batch Upload Template: Load in the project batch upload template and fill it out.

prj_bu <- prj
prj_bu$project_id <- prj_id
prj_bu$initiative_id <- 1
prj_bu$project_bait_type <- "None"
prj_bu$project_blank_images <- "No"
prj_bu$project_species <- "Individual"


######
# Camera Batch Upload Template: Fill in the information relatd to the cameras/sensors used in your project
# First need to get the number of cameras used in the project

cam_bu <- cam
cam_bu$project_id <- prj_id

######
# Deployment Batch Upload Template: Fill in the information related to each deployment. A deployment is a sensor 
# observing wildlife for some amount of time in a specific location. 

# TODO


dep_count <- nrow(data[data$Event=="START",]) - 1

dep_bu <- dep
dep_bu$project_id <- prj_id
dep_bu$start_date <- paste(paste(lapply(str_split(dep$start_date, "/"), `[[`, 3),
                                 str_pad(lapply(str_split(dep$start_date, "/"), `[[`, 1), 2, pad="0"),
                                 str_pad(lapply(str_split(dep$start_date, "/"), `[[`, 2), 2, pad="0"), sep="-"), "00:00:00", sep=" ")
dep_bu$end_date <- paste(paste(lapply(str_split(dep$end_date, "/"), `[[`, 3),
                               str_pad(lapply(str_split(dep$end_date, "/"), `[[`, 1), 2, pad="0"),
                               str_pad(lapply(str_split(dep$end_date, "/"), `[[`, 2), 2, pad="0"), sep="-"), "00:00:00", sep=" ")


rm(dep_count, start_data, stop_data, dep_raw)

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
img_raw$pSubfolder <-  str_pad(img_raw$Subfolder, 6, pad="0")
img_raw$location <- paste("gs://cadfw/Deer_Program",
                          prj_bucket,
                          img_raw$Site,img_raw$pSubfolder,
                          paste("IMG_",gsub(" ", "0", format(img_raw$Reference, width=3)),".JPG", sep=""), sep="/")
img_raw$location <- gsub("00NONE/", "", img_raw$location)

img_raw$Date <- gsub("3018", "2018", img_raw$Date)

dep_agg <- img_raw%>%
  group_by(Site) %>% 
  summarize(latest_date = max(Date)) %>% 
  mutate(latest_year = substr(latest_date, 0, 4))
year <- median(as.numeric(dep_agg$latest_year))

img_raw$dep_id <- paste(img_raw$Site, year, sep="-")

# Mapping WI Taxon values
img_raw <- left_join(img_raw, wi_key, by="Event", all.x = TRUE)

timestamps <- read.csv("/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/exifCollection/Carson_river_exifs.csv")
timestamps$location <- paste("gs://cadfw/Deer_Program",
                             prj_bucket, timestamps$SourceFile, sep="/")

img_raw <- merge(x = img_raw, y = timestamps, by = "location", all.x = TRUE)

id_by <- sub("REVIEWER1_", "", getSheetNames(data_path)[1])
id_by <- gsub("[^[:alpha:]]+", "",id_by)

img_raw[is.na(img_raw$Count),"Count"] <- 1
img_raw[as.numeric(img_raw$Count) > 50,"Count"] <- 50

#Removing temporarily incompatible images
img_raw <- img_raw[!is.na(img_raw$createDate),]
img_raw <- img_raw[img_raw$location!="gs://cadfw/Deer_Program/Carson River/CR-14/IMG_0350.JPG",]

# Creating Batch Upload File
img_count <- nrow(img_raw)

img_bu <- wi_batch_function("Image", img_count)
img_bu$project_id <- prj_id
img_bu$deployment_id <- img_raw$dep_id
img_bu$image_id <- paste(img_raw$Site,img_raw$pSubfolder, img_raw$Reference, sep="-")
img_bu$location <- img_raw$location
img_bu$identified_by <- id_by

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
img_bu$age <- ""
img_bu$sex <- ""
img_bu$animal_recognizable <- ""
img_bu$individual_id <- ""
img_bu$individual_animal_notes <- ""
img_bu$markings <- ""
img_bu$external_sequence_id <- ""


rm(img_raw, indices, unlisted_ref, dep_agg, year, img_count, timestamps)
write.table(cam_bu,file="/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/Carson River/output/cameras.csv", row.names = FALSE, sep=",")
write.table(dep_bu,file="/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/Carson River/output/deployments.csv", row.names = FALSE, sep=",")
write.table(img_bu,file="/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/Carson River/output/images.csv", row.names = FALSE, sep=",")
write.table(prj_bu,file="/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/Carson River/output/projects.csv", row.names = FALSE, sep=",")

