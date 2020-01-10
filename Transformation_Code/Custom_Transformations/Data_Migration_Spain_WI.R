# WWF SPAIN data sheet to Wildlife Insights Data Migration Tool
# We are starting this based on a dataset from WWF Spain
# Goal: Build a mapping from WWF Spain data sheet format (.csv file) into 
# WI Batch Upload Template
# 1. Do the mappings
# 2. Fill in data attributes as needed.
# 3. Load the Batch Upload Template and conduct QA/QC (need to define.)

######
# Clear workspace
rm(list=ls())
# Set your working directory 
setwd("~/work/WildlifeInsights/Wildlife-Insights----Data-Migration")
# Load Libraries
library(dplyr)
library(googlesheets)
library(lubridate)
library(stringr)
source('wi_functions.R')


# TASKS
# Need to handle the breaks in deployment. Create more deployments that deal with the time gaps.
######
# Load your data
######
ct_data <- read.csv("WWF_Data_Spain/WI_WWFSpain_PnImages_EN.csv", fileEncoding="UTF-8-BOM")
# Load in the new deployment information by WWF. C
new_deployments <- read.csv("WWF_Data_Spain/new_deployments.csv", stringsAsFactors = FALSE)
# Conver to ISO DateStandard
new_deployments$Setup_ymd <- mdy(new_deployments$Setup_Date)
new_deployments$Retrieval_ymd <- mdy(new_deployments$Retrieval_Date)

######
# Project Batch Upload Template: Load in the project batch upload template and fill it out.
dep_length <- 1
prj_bu <- wi_batch_function("Project",dep_length)

# Many of the project variables may not be found in your dataset. If you can get them from your
# data great! Otherwise type them in here.
prj_bu$project_id <- "WI-WWFSPAIN-PILOT"
prj_bu$project_name <- "WWF_Spain_Lynx"
prj_bu$project_objectives <- "Monitoring of Lynx population"
prj_bu$project_species <- "Multiple" # Multiple or Single Species
prj_bu$project_species_individual  <- NA # If single list out the species (Genus species and comma separated)
prj_bu$project_sensor_layout <- "Systematic " # Options:Systematic, Randomized, Convenience,  Targeted
prj_bu$project_sensor_layout_targeted_type <-  NA
prj_bu$project_bait_use <- "No"  #Was bait used? Options: Yes,Some,No
prj_bu$project_bait_type <- NA
prj_bu$project_stratification <- "No" #Options: Yes, No
prj_bu$project_stratification_type <- NA
prj_bu$project_sensor_method <- "Sensor detection"
prj_bu$project_individual_animals <- "No" #Options: Yes, No
prj_bu$project_blank_images <- "No" # Were blanks removed? Options: Yes, No
prj_bu$project_sensor_cluster <- "No"
prj_bu$project_admin <- "Antón Álvarez"
prj_bu$project_admin_email <- "antonalvarezbc@gmail.com"
prj_bu$project_admin_organization <- "WWF Spain" #projects$`Project Owner (Organization or Individual)`
prj_bu$country_code <- "ESP"
prj_bu$embargo <- 24 # 0-24 months
prj_bu$metadata_license <- "CC-BY" # Two options: CC0,CC-BY
prj_bu$image_license <- "CC-BY-NC" # Three options: CC0,CC-BY,CC-BY-NC



######
# Camera Batch Upload Template: Fill in the information relatd to the cameras/sensors used in your project
# First need to get the number of cameras used in the project
#cam_info <- distinct(ct_data,`Camera ID`,`Serial Number`,Make,Model,`Year Purchased`)
num_sensors <- 1 #length(unique(cam_info$`Camera ID`))
# Get the empty Camera template
cam_bu <- wi_batch_function("Camera",num_sensors)
# Fill out each Camera field
cam_bu$project_id <- prj_bu$project_id # If more than one error for now
cam_bu$camera_id <- 1
cam_bu$make <- unique(ct_data$CameraManufacturer)
cam_bu$model <- NA
# If serial number and year purchased are available add them in as well.
cam_bu$serial_number <- NA
cam_bu$year_purchased <- NA


######
# Deployment Batch Upload Template: Fill in the information related to each deployment. A deployment is a sensor 
# observing wildlife for some amount of time in a specific location. 
# 
# 1. Establish unique deployments - Should be Site.Name + pair(SessionStart.Date--> Session.End.Date)
# This dataset needs the deployments created. Create them first in the main data frame and then fill in the
# the deployments batch template.
# Join the corrected deployments into the main dataframe
ct_data_dep <- left_join(ct_data,new_deployments,by="Station")
# Create a deployment for every record
ct_data_dep$deployment <- paste(ct_data_dep$Station,ct_data_dep$Setup_ymd,ct_data_dep$Retrieval_ymd,sep="-")

# 2. Create a distinct dataframe based on deployments
dep_temp <- distinct(ct_data_dep,Station,Setup_ymd,Retrieval_ymd, .keep_all = TRUE ) 

# 3. Get the empty deployement dataframe
dep_bu <- wi_batch_function("Deployment",nrow(dep_temp))

# 4. Fill in the deployment batch upload template
dep_bu$project_id <- unique(prj_bu$project_id) # If more than one error for now
dep_bu$deployment_id <- dep_temp$deployment
dep_bu$placename <- dep_temp$Station
dep_bu$longitude <- dep_temp$Longitude
dep_bu$latitude <- dep_temp$Latitude
dep_bu$start_date <- dep_temp$Setup_ymd
dep_bu$end_date <- dep_temp$Retrieval_ymd
dep_bu$event <- NA
dep_bu$array_name <- NA
dep_bu$bait_type <- "None" # Note that if bait was ussed but it was not consistent across all deployments, this is where you enter it. 
# Logic may be needed to figure out which deployments had bait and which didn't. Similar thing if "bait type" was vaired in deployments.
# Options: Yes, some, No.  We may need a way to assign this if answer = "some".
dep_bu$bait_description <- NA
dep_bu$feature_type <- "Road dirt" # Road paved, Road dirt, Trail hiking, Trail game, Road underpass, Road overpass, Road bridge, Culvert, Burrow, Nest site, Carcass, Water source, Fruiting tree, Other 
#dep_bu$feature_type[which(is.na(dep_temp$`Feature Type`))] <- "None"
dep_bu$feature_type_methodology <- NA
dep_bu$camera_id <- 1
dep_bu$quiet_period  <- NA
dep_bu$camera_functioning <- "Camera Functioning"  # Required: Camera Functioning,Unknown Failure,Vandalism,Theft,Memory Card,Film Failure,Camera Hardware Failure,Wildlife Damage
dep_bu$sensor_height  <- "Knee height"
dep_bu$height_other  <- NA
dep_bu$sensor_orientation  <- "Parallel"
dep_bu$orientation_other  <- NA
dep_bu$recorded_by <- NA


######
# Image Batch Upload Template: Fill in the information related to each image
# 
# 1. Import clean taxonomy and joing with the images worksheet.
# Taxonomy
# Load in your clean taxonomy. Clean taxononmy is created using the WI_Taxonomy.R file.
your_taxa <- read.csv("WWF_Data_Spain/WWF-SPAIN-Matching_Taxonomy.csv",colClasses = "character",strip.white = TRUE,na.strings="")
#Create a join column that accounts for both species and non-species labels from your 
ct_data_join <- left_join(ct_data_dep,your_taxa,by="Species")

# 3. Deal with date formats
ct_data_join$new_date <- as.POSIXct(strptime(ct_data_join$DateTimeOriginal,"%d/%m/%y %H:%M"))
ct_data_join$new_date1 <- as.POSIXct(strptime(ct_data_join$DateTimeOriginal,"%d/%m/%Y %H:%M"))
# Merge the two date types in a single attribute
ct_data_join$new_date[which(is.na(ct_data_join$new_date))] <- ct_data_join$new_date1[which(is.na(ct_data_join$new_date))]
#ct_data_join$new_date <-  ymd_hm(ct_data_join$DateTimeOriginal)
date_check <- as.data.frame(unique(paste(ct_data_join$DateTimeOriginal,ct_data_join$new_date,ct_data_join$new_date1, sep=" | ")))
df_date <- distinct(ct_data_join, new_date)
# 4. Load in the Image batch upload template
image_bu <- wi_batch_function("Image",nrow(ct_data))

######
# Image .csv template
image_bu$project_id<- prj_bu$project_id
image_bu$deployment_id <- ct_data_join$deployment
image_bu$image_id <- as.character(ct_data_join$FileName)
#gs://cameratraprepo-vcm/wwf-spain_lynx/Media/L1.zip
image_bu$location <- paste("gs://cameratraprepo-vcm/wwf-spain_lynx/Media/",str_extract(ct_data_join$Directory,"[A-Za-z0-9]{2}$"),"/",ct_data_join$FileName,".JPG",sep="")
image_bu$is_blank[which(ct_data_join$commonNameEnglish == "Blank")] <- "Yes" # Set Blanks to Yes, 
image_bu$is_blank[which(ct_data_join$commonNameEnglish != "Blank")] <- "No"
image_bu$wi_taxon_id <- ct_data_join$uniqueIdentifier
image_bu$class <- ct_data_join$class
image_bu$order <- ct_data_join$order
image_bu$family <- ct_data_join$family
image_bu$genus <- ct_data_join$genus
image_bu$species <- ct_data_join$species
image_bu$common_name <- ct_data_join$commonNameEnglish
image_bu$uncertainty <- ct_data_join$Uncertainty
image_bu$timestamp <- as.character(ct_data_join$new_date)
image_bu$age <- NA
image_bu$sex <- NA
image_bu$animal_recognizable <- NA
image_bu$number_of_animals <- as.character(ct_data_join$numberMetadata)
image_bu$individual_id <- NA
image_bu$individual_animal_notes <- as.character(ct_data_join$especieMetadata)
image_bu$highlighted <- NA
image_bu$color <- NA
image_bu$identified_by <- NA

# Get a clean site name first - no whitespaces
site_name_clean <- gsub(" ","_",prj_bu$project_name)
# Creater the directory
dir.create(path = paste("WWF_Data_Spain/",site_name_clean,sep=""))

# Create the directory
#dir.create(path = site_name_clean)
# Change any NAs to emptyp values
prj_bu <- prj_bu %>% replace(., is.na(.), "")
cam_bu <- cam_bu %>% replace(., is.na(.), "")
dep_bu <- dep_bu %>% replace(., is.na(.), "")
image_bu <- image_bu %>% replace(., is.na(.), "")

# Write out the 4 csv files for required for Batch Upload
write.csv(prj_bu,file=paste("WWF_Data_Spain/",site_name_clean,"/","projects.csv",sep=""), row.names = FALSE)
write.csv(cam_bu,file=paste("WWF_Data_Spain/",site_name_clean,"/","cameras.csv",sep=""),row.names = FALSE)
write.csv(dep_bu,file=paste("WWF_Data_Spain/",site_name_clean,"/","deployments.csv",sep=""),row.names = FALSE)
write.csv(image_bu,file=paste("WWF_Data_Spain/",site_name_clean,"/","images.csv",sep=""),row.names = FALSE)


