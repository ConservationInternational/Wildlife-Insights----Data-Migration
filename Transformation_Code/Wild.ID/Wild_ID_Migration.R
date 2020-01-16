# Wild.ID Migration Script
# Eric Fegraus. October 2019
# Purpose: The goal of this script is to load the Wild.ID export and convert it 
# into the Batch Upload Templates needed to ingest into Wildlife Insights.
# Note that within Wild.ID there are several options for exporting metadata.
# Selecting the .csv or .xls option in Export-->Export Data and Image --> CSV Format 
# or Export --> Export Data and Image --> Excel Format will result in a different file structure. 
# The format expected here comes from selecting Export --> Export Data and Image --> Wildlife Insights Format
# This code uses a real dataset collected in Peru. You will need to slightly modify
# this code to meet the needs and objectives of your camera trapping project.
# Key Steps:
# 1. Read in your data
# 2. Starting filling out the Batch Upload Template dataframes
# 3. Do the taxonomic mapping between your data and Wildlife Insights.  See the
#      wi_taxonomy.R code to download a dataframe of all WI taxonomy and the unique identifiers.
# 4. Validate your batch upload files by contacting info@wildlifeinsights.org.

# Clear all variables
rm(list = ls())
# Load libraries
library(dplyr)
library(readxl)
library(googlesheets)
library(lubridate)
source('Transformation_Code/Generic_Functions/wi_functions.R')

# Set the directory path. This is relative to this Github repo. If you have cloned or 
# downloaded the repo it should work. If used outside of the repo you will need to modify this.

dir_path <- "Datasets/Example_Dataset/CafeFauna/"

# Load Wild.ID export 1
images_1 <- read_excel(paste(dir_path,"original_dataset/CafeFaunaAMPeru_Wild_ID_ALM_Wild_ID_ALM.xlsx",sep=""),sheet="Image")
deployments_1 <- read_excel(paste(dir_path,"original_dataset/CafeFaunaAMPeru_Wild_ID_ALM_Wild_ID_ALM.xlsx",sep=""),sheet="Deployment")
cameras_1 <- read_excel(paste(dir_path,"original_dataset/CafeFaunaAMPeru_Wild_ID_ALM_Wild_ID_ALM.xlsx",sep=""),sheet="Cameras")
projects_1 <- read_excel(paste(dir_path,"original_dataset/CafeFaunaAMPeru_Wild_ID_ALM_Wild_ID_ALM.xlsx",sep=""),sheet="Project")
####
# Load Wild.ID export 2
images_2 <- read_excel(paste(dir_path,"original_dataset/CafeFaunaAMPeru_Wild_ID_ALM2_Wild_ID_ALM2.xlsx",sep=""),sheet="Image")
deployments_2 <- read_excel(paste(dir_path,"original_dataset/CafeFaunaAMPeru_Wild_ID_ALM2_Wild_ID_ALM2.xlsx",sep=""),sheet="Deployment")
cameras_2 <- read_excel(paste(dir_path,"original_dataset/CafeFaunaAMPeru_Wild_ID_ALM2_Wild_ID_ALM2.xlsx",sep=""),sheet="Cameras")
projects_2 <- read_excel(paste(dir_path,"original_dataset/CafeFaunaAMPeru_Wild_ID_ALM2_Wild_ID_ALM2.xlsx",sep=""),sheet="Project")

# Merge these exports together because they are one project. Many camera trapping
# projects may be just one project in Wild.iD
projects_1 <- projects_1[1,]
projects <- projects_1
images <- rbind(images_1,images_2)
deployments <- rbind(deployments_1,deployments_2)
cameras <- rbind(cameras_1,cameras_2)
####
# Handle any data irregularities
#
# Adjust datetime stamp format
deployments$new_begin <- ymd(deployments$`Camera Deployment Begin Date`)
deployments$new_end <- ymd(deployments$`Camera Deployment End Date`)


######
# Project Batch Upload Template: Load in the project batch upload template and fill it out.
dep_length <-1
prj_bu <- wi_batch_function("Project",dep_length)

# Many of the project variables may not be found in your dataset. If you can get them from your
# data great! Otherwise type them in here. 
prj_bu$project_id <- projects$`Project ID`
prj_bu$project_name <- projects$`Project Name`
prj_bu$project_objectives <- "Evaluate the effects of coffee conservation agreements on wildlife and biodiversity co-benefits in the Alto Mayo landscape in San Martin, Peru."
prj_bu$project_species <- "Multiple" # Multiple or Single Species
prj_bu$project_species_individual  <- NA # If single list out the species (Genus species and comma separated)
prj_bu$project_sensor_layout <- "Systematic" # Options:Systematic, Randomized, Convenience,  Targeted 
prj_bu$project_sensor_layout_targeted_type <-  NA
prj_bu$project_bait_use <- "No"  #Was bait used? Options: Yes,Some,No
prj_bu$project_bait_type <- NA
prj_bu$project_stratification <- "No" #Options: Yes, No
prj_bu$project_stratification_type <- NA
prj_bu$project_sensor_method <- "Sensor detection"
prj_bu$project_individual_animals <- "No" #Options: Yes, No
prj_bu$project_blank_images <- "No" # Were blanks removed? Options: Yes, No
prj_bu$project_sensor_cluster <- "No"
prj_bu$project_admin <- "Jorge Ahumada" #projects$`Principal Investigator`
prj_bu$project_admin_email <- "jahumada@conservation.org" #projects$`Principal Investigator Email`
prj_bu$project_admin_organization <- "Conservation International" #projects$`Project Owner (Organization or Individual)`
prj_bu$country_code <- projects$`Country Code`
prj_bu$embargo <- 0 # 0-24 months
prj_bu$metadata_license <- "CC-BY" # Two options: CC0,CC-BY
prj_bu$image_license <- "CC-BY-NC" # Three options: CC0,CC-BY,CC-BY-NC


######
# Camera Batch Upload Template: Fill in the information relatd to the cameras/sensors used in your project
# First need to get the number of cameras used in the project
cam_info <- distinct(cameras,`Camera ID`,`Serial Number`,Make,Model,`Year Purchased`)
num_sensors <- length(unique(cam_info$`Camera ID`))
# Get the empty Camera template
cam_bu <- wi_batch_function("Camera",num_sensors)
# Fill out each Camera field
cam_bu$project_id <- projects$`Project ID` # If more than one error for now
cam_bu$camera_id <- cam_info$`Camera ID`
cam_bu$make <- cam_info$Make
cam_bu$model <- cam_info$Model
# If serial number and year purchased are available add them in as well.
cam_bu$serial_number <- cam_info$`Serial Number`
cam_bu$year_purchased <- cam_info$`Year Purchased`
# Notes: We will also try to get information from image EXIF data upon data ingestion into WI. 


######
# Deployment Batch Upload Template: Fill in the information related to each deployment. A deployment is a sensor 
# observing wildlife for some amount of time in a specific location. 
# 
# 1. Establish unique deployments - Should be Site.Name + pair(SessionStart.Date--> Session.End.Date)
#ct_data_taxa$deployments <- paste(ct_data_taxa$Site.Name,ct_data_taxa$Session.Start.Date,ct_data_taxa$Session.End.Date,sep="-")
# 2. Create a distinct dataframe based on deployments
dep_temp<-distinct(deployments,`Deployment ID`,.keep_all = TRUE )

# 3. Get the empty deployement dataframe
dep_bu <- wi_batch_function("Deployment",nrow(dep_temp))
# 4. Fill in the deployment batch upload template
dep_bu$project_id <- unique(prj_bu$project_id) # If more than one error for now
dep_bu$deployment_id <- dep_temp$`Deployment ID`
dep_bu$placename <- dep_temp$`Depolyment Location ID`
dep_bu$longitude <- dep_temp$`Longitude Resolution`
dep_bu$latitude <- dep_temp$`Latitude Resolution`
dep_bu$start_date <- dep_temp$new_begin
dep_bu$end_date <- dep_temp$new_end
dep_bu$event <- dep_temp$`Event Name`
dep_bu$array_name <- dep_temp$`Array Name (Optional)`
dep_bu$bait_type <- "None" # Note that if bait was ussed but it was not consistent across all deployments, this is where you enter it. 
# Logic may be needed to figure out which deployments had bait and which didn't. Similar thing if "bait type" was vaired in deployments.
# Options: Yes, some, No.  We may need a way to assign this if answer = "some".
dep_bu$bait_description <- NA
dep_bu$feature_type <- dep_temp$`Feature Type` # Road paved, Road dirt, Trail hiking, Trail game, Road underpass, Road overpass, Road bridge, Culvert, Burrow, Nest site, Carcass, Water source, Fruiting tree, Other 
dep_bu$feature_type[which(is.na(dep_temp$`Feature Type`))] <- "None"
dep_bu$feature_type_methodology <- NA
dep_bu$camera_id <- dep_temp$`Camera ID`
dep_bu$quiet_period  <- dep_temp$`Quiet Period Setting`
dep_bu$camera_functioning[which(dep_temp$`Camera Hardware Failure` == "Functioning")] <- "Camera Functioning"  # Required: Camera Functioning,Unknown Failure,Vandalism,Theft,Memory Card,Film Failure,Camera Hardware Failure,Wildlife Damage
dep_bu$camera_functioning[which(is.na(dep_temp$`Camera Hardware Failure`))] <- "Camera Functioning"
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
your_taxa <- read.csv(paste(dir_path,"taxonomic_mapping_template_ALM.csv",sep=""),colClasses = "character",strip.white = TRUE,na.strings="")
#Create a join column that accounts for both species and non-species labels from your 
your_taxa$join_taxa <- your_taxa$original_gs
# Add in the non-species original names
your_taxa$join_taxa[which(!is.na(your_taxa$Your_nonspecies))] <- your_taxa$Your_nonspecies[which(!is.na(your_taxa$Your_nonspecies))]
# Do the same with the images dataframe
images$join_taxa <- images$`Genus Species`
images$join_taxa[which(is.na(images$join_taxa))] <- images$`Photo Type`[which(is.na(images$join_taxa))]
# Join the WI taxonomy back into the images dataframe.
images_taxa <- left_join(images,your_taxa,by="join_taxa")
# Check the taxa
check <- distinct(images_taxa,class,order,family,genus,species,commonNameEnglish,uniqueIdentifier)
no_wi <- filter(images_taxa, is.na(uniqueIdentifier))
# Pulling out records that don't have unique identifier (this is a result of a photo.Type is NA)
# Create a check. If Photo.Type is.na there is an error with these or they have not bee identified.

images_taxa <- filter(images_taxa, !is.na(uniqueIdentifier))
# 2. Image file path adjustments
# Change the file path names for your images. Supply what your original path (original_path) with a replacement string (sub_path)
# Once your images are in GCP they will have an address like:
# gs://cameratraprepo-vcm/CafeFaunaAMPeru/Wild_ID_ALM/ALM_2018_249-1/IMG_0001.JPG
# Handle any windows directory backslashes
images_taxa$new_location <- gsub("\\\\","/",images_taxa$Location)
images_taxa$wi_path <- paste("gs://cameratraprepo-vcm/CafeFaunaAMPeru/Wild_ID_",images_taxa$`Project ID`,"/",images_taxa$new_location,sep="")

# If all images were identified by one person, set this here. Otherwise comment this out.
#image_identified_by <- Someone's name"

# 3. Load in the Image batch upload template
image_bu <- wi_batch_function("Image",nrow(images_taxa))

######
# Image .csv template
image_bu$project_id<- unique(prj_bu$project_id)
image_bu$deployment_id <- images_taxa$`Deployment ID`
image_bu$image_id <- images_taxa$`Image ID`
image_bu$location <- images_taxa$wi_path  
image_bu$is_blank[which(images_taxa$commonNameEnglish == "Blank")] <- "Yes" # Set Blanks to Yes, 
image_bu$is_blank[which(images_taxa$commonNameEnglish != "Blank")] <- "No"
image_bu$wi_taxon_id <- images_taxa$uniqueIdentifier
image_bu$class <- images_taxa$class
image_bu$order <- images_taxa$order
image_bu$family <- images_taxa$family
image_bu$genus <- images_taxa$genus
image_bu$species <- images_taxa$species
image_bu$common_name <- images_taxa$commonNameEnglish
image_bu$uncertainty <- images_taxa$Uncertainty
image_bu$timestamp <- images_taxa$`Date_Time Captured`
image_bu$age <- images_taxa$Age
image_bu$sex <- images_taxa$Sex
image_bu$animal_recognizable <- images_taxa$`Animal recognizable (Y/N)`
image_bu$number_of_animals <- images_taxa$Count
image_bu$individual_id <- images_taxa$`Individual ID`
image_bu$individual_animal_notes <- images_taxa$`Individual Animal Notes`
image_bu$highlighted <- NA
image_bu$color <- NA
image_bu$identified_by <- images_taxa$`Photo Type Identified by`
# Get a clean site name first - no whitespaces
site_name_clean <- gsub(" ","_",prj_bu$project_name)
site_name_clean <- paste(site_name_clean,"_wi_batch_upload",sep="")

# Create the directory
dir.create(path = paste(dir_path,site_name_clean, sep=""))
# Change any NAs to emptyp values
prj_bu <- prj_bu %>% replace(., is.na(.), "")
cam_bu <- cam_bu %>% replace(., is.na(.), "")
dep_bu <- dep_bu %>% replace(., is.na(.), "")
image_bu <- image_bu %>% replace(., is.na(.), "")

# Write out the 4 csv files for required for Batch Upload. 
# This directory needs to be uploaded to the Google Cloud with the filenames named exactly
# as written below. They have to be called: projects.csv, cameras.csv,deployments.csv,images.csv
write.csv(prj_bu,file=paste(dir_path,site_name_clean,"/","projects.csv",sep=""), row.names = FALSE)
write.csv(cam_bu,file=paste(dir_path,site_name_clean,"/","cameras.csv",sep=""),row.names = FALSE)
write.csv(dep_bu,file=paste(dir_path,site_name_clean,"/","deployments.csv",sep=""),row.names = FALSE)
write.csv(image_bu,file=paste(dir_path,site_name_clean,"/","images.csv",sep=""),row.names = FALSE)

