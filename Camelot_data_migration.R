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
ct_data <- read.csv("data/South Chilcotins Wildlife Survey.csv")
# Establish any variables needed for each project (i.e. not found in the datafile)

#PROJECT METADATA- UPDATE ALL INFORMATION HERE
PrjPubDate <- 24 # we may delete this as it is the same PrjEmbargo
PrjName<-"South Chilcotins"
PrjObj <-" Here is my objective"
PrjMethod <-" Here are my methods" 
PrjAdmin <- "Arno"
PrjAdminEmail <- "arno@wwf.org"
PrjAdminOrg <- "WWF" # This should be pulled from WI database (if the organization is already registered)
PrjCC <- "?" #unique(ct_data$Country.Primary.Location.Name) # Make this text input by user..otherwise need to build function to find three leter ISO country code
PrjDataUse <- "?"
PrjEmbargo <- 24
# Project - We will need to add more fields for the new project level questions

# CAMERA QUESTIONS
  # None
  # For now we will assume we will get Make and Model information from EXIF reader upon data ingestion into WI.

#DEPLOYMENT QUESTIONS
  # Dataset question: Trap station ID - what is it?
  # Dataset question: Trap Station Session Camera ID ..what is it?
  # Dataset question: Relationship of Camera Name with Camera ID?
  # Dataset question: Bait Type - Was bait used in this project? 
  # Dataset question: Quite Period and Camera Failure Details are required. Are these in the dataaset?

#IMAGE QUESTIONS
  # Dataset question: Location - tell me what to limit the string and i'll include this into the script. It will be useful in other situations.
  # Dataset question: Blanks - where are all the blank images?
  # Dataset question: Photo_Type_Identified_by - this is required. Can you find out this person(s)? Alternative is we make it not required.
  # Count: Do we want this normalized to one row per image or one row per observation?
  # Image_use_restrictions,IUCN_Identification_Numbe, TSN_Identification_Number: we will probably delete
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
cam_df_length <- length(unique(ct_data$Camera.ID))
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
prj_dff$Publish_Date <- PrjPubDate # Should we keep this?
prj_dff$Project_Name <- PrjName  
prj_dff$`Project_Objectives_(WI_Event_Objectives)` <- PrjObj
prj_dff$Project_Methodology <- PrjMethod
prj_dff$Project_Admin <- PrjAdmin
prj_dff$Project_Admin_Email <- PrjAdminEmail 
prj_dff$Project_Admin_Organization <- PrjAdminOrg
prj_dff$Country_Code <- PrjCC
prj_dff$Project_Data_Use_and_Constraints <- PrjDataUse
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
dep_dff$Event
dep_dff$Array_Name
dep_dff$Deployment_Location__ID  <- dep_temp$Site.Name
dep_dff$Longitude <- dep_temp$Camelot.GPS.Longitude
dep_dff$Latitude <- dep_temp$Camelot.GPS.Latitude
dep_dff$Camera_Deployment_Begin_Date <- dep_temp$Session.Start.Date
dep_dff$Camera_Deployment_End_Date <- dep_temp$Session.End.Date
dep_dff$Bait_Type 
dep_dff$Bait_Description
dep_dff$Feature_Type
dep_dff$Feature_Type_Methodology
dep_dff$Camera_ID <- dep_temp$Camera.ID
dep_dff$Quiet_Period_Setting
dep_dff$Sensitivity_Setting
#dep_dff$Restriction_on_access - Remove this
dep_dff$Camera_Failure_Details



######
# Image .csv template
# 1. Rename columns
image_dff$Project_ID <- prj_dff$Project_ID
image_dff$Deployment_ID <- ct_data$deploymentsc
image_dff$Image_ID <- ct_data$Media.Filename
image_dff$Location <- ct_data$Absolute.Path
image_dff$Blank <- # Need some logic here
image_dff$Photo_Type_Identified_by # What to do here? It is required
image_dff$Genus_Species <- ct_data$Species # Lots of quality control to do here.
image_dff$Species_Common_Name <- ct_data$Species.Common.Name  # Lots of quality control to do here.
image_dff$Uncertainty
image_dff$IUCN_Identification_Number # potentially delete
image_dff$TSN_Identification_Number  # potentially delete
image_dff$Date_Time_Captured  <- ct_data$Date.Time
image_dff$Age <- ct_data$Life.stage
image_dff$Sex <- ct_data$Sex
image_dff$Individual_ID
image_dff$Count  # Is there a count column?  It looks like this file is normalized by animal per image
image_dff$`Animal_recognizable_(Y/N)`
image_dff$Individual_Animal_Notes
image_dff$Image_Favorite
image_dff$Color <- ct_data$Colour

# Color: interesting attribute to consider adding to batch upload.
# Altitude: Do we want to get this? or generate globally?


######
# Write out the 4 csv files for batch upload
write.csv(prj_dff,file=paste(PrjName,"_project.csv",sep=""))
write.csv(cam_dff,file=paste(PrjName,"_camera.csv",sep=""))
write.csv(dep_dff,file=paste(PrjName,"_deployment.csv",sep=""))
write.csv(image_dff,file=paste(PrjName,"_image.csv",sep=""))


