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
data15_path <- "/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/EDTA/EDTA_2015_ImageData.xlsx"
data16_path <- "/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/EDTA/EDTA_2016_ImageData.xlsx"
data17_path <- "/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/EDTA/ETDA_2017_ImageData.xlsx"
data18_path <- "/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/EDTA/ETDA_2018_ImageData.xlsx"
data19_path <- "/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/EDTA/Catalogued_Data-Deer Program-ETDA-Metadata-CamInterp_ETDA_2019_Ogata_030221.xlsx"
data20_path <- "/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/EDTA/Catalogued_Data-Deer Program-ETDA-Metadata-CamInterp_ETDA_2020_OGATA_030921.xlsx"

# Path of data in BU formatting
cam_path <- "/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/EDTA/camera.csv"
dep_path <- "/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/EDTA/deployment.csv"
prj_path <- "/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/EDTA/project.csv"

prj_id = "ETDA"
prj_bucket <- "ETDA"

#Loading the data in

## Loading in the image file data
data15 <- read_excel(data15_path, sheet=1)
data16 <- read_excel(data16_path, sheet=1)
data17 <- read_excel(data17_path, sheet=3)
data18 <- read_excel(data18_path, sheet=3)
data19 <- read_excel(data19_path, sheet=1)
data20 <- read_excel(data20_path, sheet=1)

data15$year <- "2015"
data16$year <- "2016"
data17$year <- "2017"
data18$year <- "2018"
data19$year <- "2019"
data20$year <- "2020"

## Loading in the Event-Species mappings
key15 <- read_excel(data15_path, sheet=4)
key16 <- read_excel(data16_path, sheet=4)
key17 <- read_excel(data17_path, sheet=4)
key18 <- read_excel(data18_path, sheet=4)
key19 <- read_excel(data19_path, sheet=4)
key20 <- read_excel(data20_path, sheet=4)

## Loading in the Batch upload files
cam <- read.csv(cam_path)
dep <- read.csv(dep_path)
prj <- read.csv(prj_path)

## Loading in the Wildlife Insights Taxonomical key
wi_taxonomy = read.csv("./WI_Global_Taxonomy/WI_Global_Taxonomy.csv")


#Creating WI key matching
key <- rbind(key17[, 1:3], key18, key19, key20)

names(key) <- c("Event", "commonNameEnglish", "notes")
key$splitNotes <- str_split(key$notes, " ")
key$genus <- sapply(key$splitNotes, `[[`, 1)
key$species <- sapply(key$splitNotes, tail, 1)
key <- key[!is.na(key$notes),]

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

wi_key <- wi_key[c("Event", "uniqueIdentifier")]
wi_key <- rbind(wi_key, read.csv("~/Documents/Wildlife_Insights/CDFW/CDFW_taxonomy/cdfw_wi_pairings.csv"))



#Finalizing Wi Key
wi_key <- left_join(wi_key, wi_taxonomy, by="uniqueIdentifier", all.x = TRUE)
wi_key <- wi_key[!is.na(wi_key$uniqueIdentifier),]
# Removing duplicate humans
wi_key <- wi_key[!grepl("Human-", wi_key$commonNameEnglish),]
# Removing duplicate keys
wi_key <- unique(wi_key)
rm(key15, key16, key17, key18, key19, key20, wi_taxonomy)

#Putting together image data
data15$Reviewer <- "Colbrunn Boswell"
data16$Reviewer <- "Fust Kallman"
data17$Reviewer <- "Ogata"
data18$Reviewer <- "Ogata"
data19$Reviewer <- "Ogata"
data20$Reviewer <- "Ogata"

data15$Subfolder <- ""
data16$Subfolder <- ""
data17$Subfolder <- ""

data16$Salt <- ""
data17$Salt <- ""
data18$Salt <- ""
data19$Salt <- ""
data20$Salt <- ""

data <- rbind(data15, data16, data17, data18, data19, data20)

rm(data15, data16, data17, data18, data19, data20,
   data15_path, data16_path, data17_path, data18_path, data19_path, data20_path)

######
# Project Batch Upload Template: Load in the project batch upload template and fill it out.

prj_bu <- prj
prj_bu$project_id <- prj_id
prj_bu$project_blank_images <- "No"
prj_bu$project_species <- "Individual"
prj_bu$project_species_individual <- "627c919c-29bc-439b-acde-62b3cd31f8a8"
prj_bu$initiative_id <- 1

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
dep_bu$longitude <- str_pad(dep_bu$longitude, width=11, pad="0", side="right")
dep_bu$latitude <- str_pad(dep_bu$latitude, width=11, pad="0", side="right")
dep_bu[dep_bu$camera_functioning=="Memory Card","camera_functioning"] <- "Camera Functioning"
rm(dep)

######
# Image Batch Upload Template: Fill in the information related to each image

img_raw <- data[!is.na(data$Reference),]

# ----
# Unpacking data with alphanumeric image file names

thru_data <- img_raw[grepl("[a-zA-Z]", img_raw$Reference),]
thru_data <- thru_data[!is.na(thru_data$Reference),]

# Incrementing the missing first images in the sequence
thru_data$Reference <- gsub("2017-07-02 15-27-11 M 2_3 THRU", "2017-07-02 15-28-19 M 1_3 THRU", thru_data$Reference)
thru_data$Reference <- gsub("2017-07-16 07-32-39 M 1_3 THRU", "2017-07-16 07-32-36 M 1_3 THRU", thru_data$Reference)
thru_data$Reference <- gsub("2017-07-04 04-01-32 M 1_5 THRU", "2017-07-04 01-32-13 M 1_5 THRU", thru_data$Reference)
thru_data$Reference <- gsub("2017-07-09 07-09-00 M 1_3 THRU", "2017-07-09 00-47-29 M 1_3 THRU", thru_data$Reference)
thru_data$Reference <- gsub("2017-07-1 16-41-38 M 1_3 THRU", "2017-07-01 16-41-38 M 1_3 THRU", thru_data$Reference)
thru_data$Reference <- gsub("2017-08-04 17-16 13 M 1_3 THRU", "2017-08-04 17-16-13 M 1_3 THRU", thru_data$Reference)
thru_data$Reference <- gsub("2017-07-29 4-16-57 M 1_3 THRU", "2017-07-29 04-15-26 M 1_3 THRU", thru_data$Reference)
thru_data$Reference <- gsub("2017-08-22 13-23-25 M 1_3 THRU", "2017-08-22 13-43-25 M 2_3 THRU", thru_data$Reference)
thru_data$Reference <- gsub("2017-08-22 13-23-43-24 M 1_3 THRU", "2017-08-22 13-43-24 M 1_3 THRU", thru_data$Reference)

# Decrementing the missing last images in the sequence

thru_data$Reference <- gsub("THRU 2017-07-02 15-28-28 M 2_3", "THRU 2017-07-02 15-28-27 M 3_3", thru_data$Reference)
thru_data$Reference <- gsub("THRU 2017-07-05 17-24-17 M M 3_3", "THRU 2017-07-05 17-24-23 M 3_3", thru_data$Reference)
thru_data$Reference <- gsub("THRU  2017-07-1 16-41-44 M 1_3", "THRU 2017-07-01 16-41-44 M 1_3", thru_data$Reference)
thru_data$Reference <- gsub("THRU 2017-08-04 17-16 15 M 2_3", "THRU 2017-08-04 17-16-15 M 2_3", thru_data$Reference)
thru_data$Reference <- gsub("THRU 2017-07-29 4-17-00 M 3_3", "THRU 2017-07-29 04-15-28 M 3_3", thru_data$Reference)
thru_data$Reference <- gsub("THRU 2017-08-03 19-41 M 3_3", "THRU 2017-08-03 19-50-41 M 3_3", thru_data$Reference)
thru_data$Reference <- gsub("THRU 2017-08-11 12-45 M 2_3", "THRU 2017-08-11 12-00-45 M 2_3", thru_data$Reference)

indices <- rep(1:nrow(thru_data), str_count(thru_data$Reference, ",")+str_count(thru_data$Reference, "AND")+1)

unpacked_references <- unlist(str_split(thru_data$Reference, ","))
unpacked_references <- unlist(str_split(unpacked_references, "AND"))

thru_data <- thru_data[indices,]
thru_data$Reference <- unpacked_references
extreme_references <- str_split(unpacked_references, "THRU")
thru_data$first <- lapply(extreme_references, `[[`, 1)
thru_data$last <- lapply(extreme_references, tail, 1)
thru_data <- unique(thru_data)

trueLocations <- read.csv("~/Documents/Wildlife_Insights/CDFW/deerimagefiles/EDTA/trueLocations.csv")
trueLocations$img_filename <- unlist(lapply(str_split(trueLocations$locations, "/"), tail, 1))
trueLocations$split <- str_split(trueLocations$locations, "/")
trueLocations$split_length <- str_count(trueLocations$locations, "/")
tl <- trueLocations[trueLocations$split_length>6 & grepl(".JPG", trueLocations$img_filename),]
tl$year <- unlist(lapply(tl$split, `[[`, 6))
tl$Site <- unlist(lapply(tl$split, `[[`, 7))
tl$subfolder <- unlist(lapply(tl$split, `[[`, 8))
tl[tl$subfolder==tl$img_filename,"subfolder"] <- ""
tl <- tl[!grepl("IMG_.....", tl$img_filename),]
tl <- tl[nchar(tl$img_filename)>18,]
tl$date <- as_datetime(substr(tl$img_filename, 0, 19))
tl <- tl[order(tl$Site, tl$date),]
tl_ord <- tl %>% 
  mutate(first=gsub(".JPG", "", img_filename), last=gsub(".JPG", "", img_filename)) %>% 
  select(Site, year, first, last, date, locations)



thru_exp <- merge(thru_data, tl_ord, by=c("Site","year"))

thru_exp <- thru_exp[order(thru_exp$Site, thru_exp$Reference, thru_exp$date),]

firsts <- thru_exp[which(gsub(" ", "", thru_exp$first.x)==gsub(" ", "", thru_exp$first.y)), ]
firsts$first_index <- which(gsub(" ", "", thru_exp$first.x)==gsub(" ", "", thru_exp$first.y))
firsts <- firsts %>% 
  select(-first.x, -last.x, -first.y, -last.y)

lasts <- thru_exp[which(gsub(" ", "", thru_exp$last.x)==gsub(" ", "", thru_exp$last.y)), ]
lasts$last_index <- which(gsub(" ", "", thru_exp$last.x)==gsub(" ", "", thru_exp$last.y))
lasts <- lasts %>% 
  select(-first.x, -last.x, -first.y, -last.y)

indices <- merge(firsts, lasts, by=colnames(select(thru_data, -first, -last)))



thru_exp$index <- which(!is.na(thru_exp$Reference))
thru_indices <- merge(thru_exp, indices[,c("Reference", "first_index", "last_index")], by="Reference")

thru_indices <- thru_indices[thru_indices$first_index<=thru_indices$index,]
thru_indices <- thru_indices[thru_indices$last_index>=thru_indices$index,]

thru_data <- thru_indices

rm(extreme_references, firsts, indices, lasts, thru_exp, thru_indices, tl, tl_ord)

#----
# Unpacking data with numeric image file names
dash_data <- img_raw[!grepl("[a-zA-Z]", img_raw$Reference),]

#Expanding Data for individual images
dash_data$Reference <- sub(",$", "", dash_data$Reference)
dash_data$Reference <- sub("-$", "", dash_data$Reference)

indices <- rep(1:nrow(dash_data), str_count(dash_data$Reference, ",")+1)

dash_data$Reference <- str_split(dash_data$Reference, ",")

unlisted_ref <- unlist(dash_data$Reference)
dash_data <- dash_data[indices, ]

dash_data$Reference <- unlisted_ref

dash_data$listed_references <- str_split(dash_data$Reference, "-")

dash_data$first <- lapply(dash_data$listed_references, `[[`, 1)
dash_data$last <- lapply(dash_data$listed_references, tail, 1)
dash_data$listed_references <- Map(":",
                                   unlist(as.numeric(dash_data$first)),
                                   unlist(as.numeric(dash_data$last)))

unlisted_ref <- unlist(dash_data$listed_references)

indices <- rep(1:nrow(dash_data), lengths(dash_data$listed_references))
dash_data <- dash_data[indices, ]
dash_data$Reference <- unlisted_ref

tl <- trueLocations[trueLocations$split_length>6 & grepl(".JPG", trueLocations$img_filename),]
tl$year <- unlist(lapply(tl$split, `[[`, 6))
tl$Site <- unlist(lapply(tl$split, `[[`, 7))
tl$subfolder <- unlist(lapply(tl$split, `[[`, 8))

tl[grepl("K|L", tl$subfolder), "Station"] <- gsub("[a-zA-JM-Z0-9_-]", "", tl[grepl("K|L", tl$subfolder), "subfolder"])
tl[grepl("K|L", tl$Site), "Station"] <- gsub("[a-zA-JM-Z0-9_-]", "", tl[grepl("K|L", tl$Site), "Site"])
tl$Site <- gsub("[a-zA-Z]", "", tl$Site)
tl$Site <- unlist(lapply(str_split(tl$Site, " "), `[[`, 1))
tl$Station <- gsub(" ", "", tl$Station)
tl$Reference <- as.numeric(gsub("[a-zA-Z._]", "", tl$img_filename))

cata_trueLocations <- read.csv("~/Documents/Wildlife_Insights/CDFW/deerimagefiles/EDTA/cata_trueLocations.csv")
cata_trueLocations$img_filename <- unlist(lapply(str_split(cata_trueLocations$locations, "/"), tail, 1))
cata_trueLocations$split <- str_split(cata_trueLocations$locations, "/")
cata_trueLocations$split_length <- str_count(cata_trueLocations$locations, "/")

cata_tl <- cata_trueLocations[cata_trueLocations$split_length>6 & grepl(".JPG", cata_trueLocations$img_filename),]
cata_tl$year <- unlist(lapply(cata_tl$split, `[[`, 8))
cata_tl$Site <- unlist(lapply(cata_tl$split, `[[`, 9))
cata_tl$Site <- unlist(lapply(str_split(cata_tl$Site, " "), `[[`, 1))
cata_tl$subfolder <- unlist(lapply(cata_tl$split, `[[`, 10))
cata_tl[grepl("K|L", cata_tl$img_filename), "Station"] <- gsub("[a-zA-JM-Z0-9_-]", "", cata_tl[grepl("K|L", cata_tl$img_filename), "img_filename"])
cata_tl[grepl("K|L", cata_tl$subfolder), "Station"] <- gsub("[a-zA-JM-Z0-9_-]", "", cata_tl[grepl("K|L", cata_tl$subfolder), "subfolder"])
cata_tl[grepl("K|L", cata_tl$Site), "Station"] <- gsub("[a-zA-JM-Z0-9_-]", "", cata_tl[grepl("K|L", cata_tl$Site), "Site"])
cata_tl$Site <- gsub("[a-zA-Z]", "", cata_tl$Site)
cata_tl$Station <- gsub(" ", "", cata_tl$Station)
cata_tl$Station <- gsub("\\(\\)[.]", "", cata_tl$Station)
cata_tl$Reference <- as.numeric(gsub("[a-zA-Z._]", "", cata_tl$img_filename))
cata_tl[grepl("[(]", cata_tl$img_filename), "Reference"] <-  unlist(lapply(str_split(cata_tl[grepl("[(]", cata_tl$img_filename), "img_filename"], "\\(|\\)"), `[`, 2))

tl_full <- rbind(tl, cata_tl)

tl_full$raw_date <- gsub("/", "", str_extract(tl_full$locations, "[0-9]{8}/|[0-9]{6}/"))
tl_full$m <- substr(tl_full$raw_date, 0, 2)
tl_full$d <- substr(tl_full$raw_date, 3, 4)

tl_full$date_val <- as.numeric(paste(tl_full$year, str_pad(tl_full$m, width=2, pad="0"), str_pad(tl_full$d, width=2, pad="0"), sep=""))

t <- merge(dash_data, tl_full[, c("year", "Site", "Station", "Reference", "locations", "date_val")], by=c("year", "Site", "Station", "Reference"), all.x=T)
t$Date_val <- as.numeric(paste(t$year, str_pad(substr(t$Date, 6, 7), width=2, pad="0"), str_pad(substr(t$Date, 9,10), width=2, pad="0"), sep=""))
t <- t[is.na(t$date_val)|t$date_val <= t$Date_val,]
t <- t[order(t$date_val, decreasing = T),]
dash_data <- t[!duplicated(t[, colnames(dash_data)]),]

img_raw <- rbind(dash_data[,append(colnames(img_raw), "locations")],
                 thru_data[,append(colnames(img_raw), "locations")])
rm(thru_data, indices, dash_data, tl, tl_full, trueLocations, t, unlisted_ref, unpacked_references)

img_raw$dep_id <- paste(paste(img_raw$Site, img_raw$Station, sep=""), img_raw$year, sep="-")

# Mapping WI Taxon values
img_raw <- left_join(img_raw, wi_key, by="Event", all.x = TRUE)

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


# Creating Batch Upload File ----
img_raw <- img_raw[!is.na(img_raw$locations)&!is.na(img_raw$uniqueIdentifier),]
img_count <- nrow(img_raw)

img_bu <- wi_batch_function("Image", img_count)
img_bu$project_id <- prj_id
img_bu$deployment_id <- img_raw$dep_id
img_bu$image_id <- gsub("gs://cadfw/Deer_Program/ETDA/","", img_raw$locations)
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

rm(img_raw, indices, unlisted_ref, img_count)

# Filtering out Deployments with no images and images with no existing deployment
dep_bu <- dep_bu[dep_bu$deployment_id %in% img_bu$deployment_id,]
img_bu <- img_bu[img_bu$deployment_id %in% dep_bu$deployment_id,]

write.table(cam_bu,file="/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/EDTA/output/cameras.csv", row.names = FALSE, sep=",")
write.table(dep_bu,file="/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/EDTA/output/deployments.csv", row.names = FALSE, sep=",")
write.table(img_bu,file="/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/EDTA/output/images.csv", row.names = FALSE, sep=",")
write.table(prj_bu,file="/Users/anthonyngo/Documents/Wildlife_Insights/CDFW/deerimagefiles/EDTA/output/projects.csv", row.names = FALSE, sep=",")

