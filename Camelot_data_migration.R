# Camelot_data_migration.R Eric Fegraus 4/17/2019
# Purpose: Camelot to Wildlife Insights Data Migration Tool
# ARNO- How was the data exported out of camelot?
# We are starting this based on a dataset from WWF Canada
# Goal: Build a mapping from Camelot export (.csv file) into 
# WI Batch Upload Template

######
# Clear workspace
rm(list=ls())
# Set your working directory 
#setwd("~/ciwork/WI")
# Load Libraries
library(dplyr)
library(googlesheets)

######
# Load your data and type in any information that cannot be captured from the dataset directly. 
ct_data <- read.csv("data/South Chilcotins Wildlife Suvey.csv")
# Establish any variables needed for each project (i.e. not found in the datafile)

#PROJECT METADATA- UPDATE ALL INFORMATION HERE
# Setting up many variables that are not found in the dataset itself.
PrjName<-"South Chilcotins Wildlife Survey 2018"
PrjObj <-"Comparison of camera trapping vs. eDNA mammal abundance estimates"
PrjSpecies <-"Multiple" # Multiple or Single Species
PrjSpeciesInd <- NA # If single list out the species (Genus species and comma separated)
PrjSensorLayout <- "Systematic" # Options:Systematic, Randomized, Convenience,  Targeted 
PrjSensorLayoutTarget <- NA
PrjBaitUse <- "No"  #Was bait used? Options: Yes,Some,No
PrjBaitUseType <- NA
PrjStrata <- "No" #Options: Yes, No
PrjStrataType <- NA
PrjSensorMethod <- "Sensor detection"
PrjIndAnimals <- "No" #Options: Yes, No
PrjBlankImages <- "Yes" # Were blanks removed? Options: Yes, No
PrjSensorCluster <- "No"
PrjAdmin <- "Robin Naidoo"
PrjAdminEmail <- "Robin.Naidoo@wwfus.org"
PrjAdminOrg <- "WWF" # This should be pulled from WI database (if the organization is already registered)
PrjCC <- "CAN" #DEV OPTION: Enter in three letter ISO code.  Consider building a function to find three leter ISO country code
PrjEmbargo <- 24

# CAMERA QUESTIONS
# For now we will assume we will get Make and Model information from EXIF reader upon data ingestion into WI.
# DEV OPTION: Consider building into this with exifr.
#DEPLOYMENT QUESTIONS
DepBait <- PrjBaitUse # Was bait used? Options: Yes, some, No.  Connect this to PrjBait...need a way to assign this if answer = "some".
  # Dataset question: Trap station ID - what is it?
  # Dataset question: Trap Station Session Camera ID ..what is it?
  # Dataset question: Relationship of Camera Name with Camera ID?
  #Dataset question: Quite Period and Camera Failure Details are required. Are these in the dataaset?

#IMAGE QUESTIONS
# Change the file path names for your images. Supply what your original path (original_path) with a replacement string (sub_path)
#original_path <- dQuote(D:\N\personal\investments\3909 Gun Creek Road\research\Camelot_DB\Media)
#sub_path <- "D:/BritishColumbia-CT"
# If all images were identified by one person, set this here. Otherwise comment this out.
image_identified_by <- " Robin Naidoo"
  # Dataset question: Location - tell me what to limit the string and i'll include this into the script. It will be useful in other situations.
  # Dataset question: Photo_Type_Identified_by - this is required. Can you find out this person(s)? Alternative is we make it not required.
  # Count: This should be one record per species with counts of those animals.
  # Date: We will need to reformat this prior to upload.



######################
# Move everything below into a function
######################
# Create and write out the batch upload templates as csv's: Project, Camera, Deployment, Images
# Load the template-- Might use this for QA/QC or for creating the final data frames that we write out.
# Or maybe not...TBD.
wi_batch<- gs_url("https://docs.google.com/spreadsheets/d/1PE5Zl-HUG4Zt0PwSfj-gJRJVbZ__LgH3VuiDW3-BKQg", visibility = "public")
project_batch <- wi_batch %>% gs_read_csv(ws="Projectv1.0")
prj_df_colnames <- project_batch$`Form Value`
prj_df_colnames <- gsub(" ","_",prj_df_colnames)
prj_dff <- data.frame(matrix(ncol = length(prj_df_colnames),nrow=1))
colnames(prj_dff) <- prj_df_colnames 
#prj_dff is now an empty dataframe

#Camerav1.0
cam_batch <- wi_batch %>% gs_read_csv(ws="Camerav1.0")
cam_df_colnames <- cam_batch$`Form Value`
cam_df_colnames <- gsub(" ","_",cam_df_colnames)
# Make cam_df_length unique to the number of cameras in the project
cam_df_length <- length(unique(ct_data$Camera.ID)) # or use nrow
cam_dff <- data.frame(matrix(ncol = length(cam_df_colnames),nrow=cam_df_length))
colnames(cam_dff) <- cam_df_colnames 

#Deploymentv1.0
dep_batch <- wi_batch %>% gs_read_csv(ws="Deploymentv1.0")
dep_df_colnames <- dep_batch$`Form Value`
dep_df_colnames <- gsub(" ","_",dep_df_colnames)
# Make dep_df_length unique to the number of cameras in the project
dep_df_length <- length(unique(paste(ct_data$Site.Name,ct_data$Session.Start.Date,ct_data$Session.End.Date,sep="-")))
dep_dff <- data.frame(matrix(ncol = length(dep_df_colnames),nrow=dep_df_length))
colnames(dep_dff) <- dep_df_colnames 

#Imagev1.0
image_batch <- wi_batch %>% gs_read_csv(ws="Imagev1.0")
image_df_colnames <- image_batch$`Form Value`
image_df_colnames <- gsub(" ","_",image_df_colnames)
# Set number of rows to full dataset.
image_df_length <- nrow(ct_data)
image_dff <- data.frame(matrix(ncol = length(image_df_colnames),nrow=image_df_length))
colnames(image_dff) <- image_df_colnames 
######
# Create each batch upload template
# Project .csv template
prj_dff$Project_ID <- unique(ct_data$Survey.Name)
prj_dff$Project_Name <- PrjName  
prj_dff$Project_Objectives <- PrjObj
prj_dff$Project_Species <- PrjSpecies
prj_dff$Project_Species_Individual  <- PrjSpeciesInd
prj_dff$Project_Sensor_Layout <- PrjSensorLayout
prj_dff$Project_Sensor_Layout_Targeted <- PrjSensorLayoutTarget
prj_dff$Project_Bait_Use <- PrjBaitUse
prj_dff$Project_Bait_Type <- PrjBaitUseType
prj_dff$Project_Stratification <- PrjStrata
prj_dff$Project_Stratification_Type <- PrjStrataType
prj_dff$Project_Sensor_Method <- PrjSensorMethod
prj_dff$Project_Individual_Animals <- PrjIndAnimals
prj_dff$Project_Blank_Images <- PrjBlankImages
prj_dff$Project_Sensor_Cluster <- PrjSensorCluster
prj_dff$Project_Admin <- PrjAdmin
prj_dff$Project_Admin_Email <- PrjAdminEmail 
prj_dff$Project_Admin_Organization <- PrjAdminOrg
prj_dff$Country_Code <- PrjCC
prj_dff$Embargo_Period <- PrjEmbargo

######
# Camera .csv template
cam_dff$Project_ID <- unique(prj_dff$Project_ID) # If more than one error for now
cam_dff$Camera_ID <- unique(ct_data$Camera.ID)

######
# Deployment .csv template - TODO - Review all of these to see what else will map?
# 1. Establish unique deployments - Should be Site.Name + pair(SessionStart.Date--> Session.End.Date)
ct_data$deployments <- paste(ct_data$Site.Name,ct_data$Session.Start.Date,ct_data$Session.End.Date,sep="-")
# 2. Create a distinct dataframe based on deployments
dep_temp<-distinct(ct_data,deployments,.keep_all = TRUE )
# 3. Create the final dataframe
dep_dff$Project_ID <- unique(prj_dff$Project_ID) # If more than one error for now
dep_dff$Deployment_ID <- dep_temp$deployments
dep_dff$Deployment_Location__ID  <- dep_temp$Site.Name
dep_dff$Longitude <- dep_temp$Camelot.GPS.Longitude
dep_dff$Latitude <- dep_temp$Camelot.GPS.Latitude
dep_dff$Camera_Deployment_Begin_Date <- dep_temp$Session.Start.Date
dep_dff$Camera_Deployment_End_Date <- dep_temp$Session.End.Date
dep_dff$Event
dep_dff$Array_Name
dep_dff$Bait_Type <- DepBait
dep_dff$Bait_Description
dep_dff$Feature_Type
dep_dff$Feature_Type_Methodology
dep_dff$Camera_ID <- dep_temp$Camera.ID
dep_dff$Quiet_Period_Setting
dep_dff$Camera_Failure_Details
dep_dff$Altitude
dep_dff$Height
dep_dff$Height_Other
dep_dff$Angle
dep_dff$Angle_Other


# Import the wi_taxonomy dataset.
wi_taxa <- readRDS(file = "wi_datafiles/wi_taxonomy.rds")
project_unique_species <- as.data.frame(unique(paste(ct_data$Species,ct_data$Species.Common.Name)))
# Write out a .csv file that the data provider will use to map into the WI taxonomic authority.
# Set number of rows to full dataset.
prj_species_df_length <- nrow(project_unique_species)
#image_dff <- data.frame(matrix(ncol = 1,nrow=prj_species_df_length)) # Add in the colnames: lookup, Species, Common, WI Genus, WI Species, WI Common OR JUST WI TAXONOMY ID
#colnames(image_dff) <- image_df_colnames 
write.csv(project_unique_species,file = "WI_batch_species_lookup.csv")

######
# Image .csv template
image_dff$Project_ID <- prj_dff$Project_ID
image_dff$Deployment_ID <- ct_data$deployments
image_dff$Image_ID <- ct_data$Media.Filename
image_dff$Location <- ct_data$Absolute.Path # Modify this to let user sub in new path.
image_dff$Blank[which(ct_data$Genus == "")] <-1 # Expand as needed as we look at more datasets from Camelot.
image_dff$Photo_Type_Identified_by <- image_identified_by
image_dff$Genus_Species <- ct_data$Species # Lots of quality control to do here.
image_dff$Species_Common_Name <- ct_data$Species.Common.Name  # Lots of quality control to do here.
image_dff$Uncertainty <- NA
image_dff$Taxonomic_Authority_or_Source  <- NA # potentially delete
image_dff$Date_Time_Captured  <- ct_data$Date.Time
image_dff$Age <- ct_data$Life.stage
image_dff$Sex <- ct_data$Sex
image_dff$Animal_recognizable <- NA
image_dff$Individual_ID <- NA
image_dff$Individual_Animal_Notes <- NA
image_dff$Image_Favorite <- NA
image_dff$Color <- ct_data$Colour


######
# Write out the 4 csv files for batch upload
write.csv(prj_dff,file=paste(PrjName,"_project.csv",sep=""))
write.csv(cam_dff,file=paste(PrjName,"_camera.csv",sep=""))
write.csv(dep_dff,file=paste(PrjName,"_deployment.csv",sep=""))
write.csv(image_dff,file=paste(PrjName,"_image.csv",sep=""))


