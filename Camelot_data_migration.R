# Camelot to Wildlife Insights Data Migration Tool
# We are starting this based on a dataset from WWF Canada
# Goal: Build a mapping from Camelot export (.csv file) into 
# WI Batch Upload Template
# 1. Do the mappings
# 2. Fill in data attributes as needed.
# 3. Load the Batch Upload Template and conduct QA/QC (need to define.)

######
# Clear workspace
rm(list=ls())
# Set your working directory 
#setwd("~/ciwork/WI")
# Load Libraries
library(dplyr)
library(googlesheets)

######
# Load your data
######
ct_data <- read.csv("data/South Chilcotins Wildlife Survey.csv")
# Establish any variables needed for each project (i.e. not found in the datafile)
# Project Level Metadata
PrjPubDate <- 24 # REVIEW
PrjName<-"South Chilcotins"
PrjObj <-" Here is my objective"
PrjMethod <-" Here are my methods"
PrjAdmin <- "Arno"
PrjAdminEmail <- "arno@wwf.org"
PrjAdminOrg <- "WWF" # This should be pulled from WI database (if the organization is already registered)
PrjCC <- "?" #unique(ct_data$Country.Primary.Location.Name) # Make this text input by user..otherwise need to build function to find three leter ISO country code
PrjDataUse <- "?"
PrjEmbargo <- 24
# Camera Level Metadata
# Make is required

# Questions
# CAMERA
# Camera Name - What is this? Put in cam_dff?
# DEPLOYMENTS
# Trap station ID - what is it?
# Trap Station Session Camera ID ..what is it?
# Relationship of Camera Name with Camera ID?

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
# Deployment .csv template
# 1. Establish unique deployments - Should be Site.Name + pair(SessionStart.Date--> Session.End.Date)
deployments <- unique(paste(ct_data$Site.Name,ct_data$Session.Start.Date,ct_data$Session.End.Date,sep="-"))
# 2. Create a distinct dataframe based on deployments



dep_dff$Project_ID <- unique(prj_dff$Project_ID) # If more than one error for now
dep_dff$Deployment_ID <-
#dep_dff$Event
dep_dff$Deployment_ID <- 
#dep_dff$Array_Name
dep_dff$Deployment_Location__ID  <- unique(ct_data$Site.Name)
dep_dff$Longitude <- ct_data$
dep_dff$Latitude
dep_dff$Camera_Deployment_Begin_Date
dep_dff$Camera_Deployment_End_Date
dep_dff$Bait_Type
dep_dff$Bait_Description
dep_dff$Feature_Type
dep_dff$Feature_Type_Methodology
dep_dff$Camera_ID
dep_dff$Quiet_Period_Setting
dep_dff$Sensitivity_Setting
dep_dff$Restriction_on_access
dep_dff$Camera_Failure_Details




######
# Image .csv template
# 1.rename columns
# 2. create any others that are needed
ct_data <- ct_data %>% rename(Location= Absolute.Path, Date_Time_Captured = Date.Time,
                              Image_ID = Media.Filename,Deployment_Location_id = Site.Name,
                              Project_ID = Survey.Name, Genus_Species = Species,
                              Latitude_Resolution = Camelot.GPS.Latitude, Longitude_Resolution = Camelot.GPS.Longitude,
                              Camera_Deployment_End_Date = Session.End.Date, Camera_Deployment_Begin_Date = Session.Start.Date,
                              Sex = Sex,Age = Life.stage
                              )
# Color: interesting attribute to consider adding to batch upload.
# Altitude: Do we want to get this? or generate globally?


######
# Write out the 4 csv files



