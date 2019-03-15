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
setwd("~/ciwork/WI")
# Load Libraries
library(dplyr)
library(googlesheets)

######
# Load your data
######
ct_data <- read.csv("data/South Chilcotins Wildlife Survey.csv")

######
# Rename Camelot attributes to WI attributes
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
# Fill in empty but required WI Atributes
#Project
# Project ID
# Publish Date
# Project Name
# Project Objectives (WI Event Objectives)
# Project Methodology
# Project Admin
# Project Admin Email
# Project Admin Organization
# Country Code
# Project Data Use and Constraints
# Embargo Period
######
# Create any custom fields to meet the data dictionary requirements



######
# Create and write out the batch upload templates as csv's: Project, Camera, Deployment, Images
# Load the template-- Might use this for QA/QC or for creating the final data frames that we write out.
# Or maybe not...TBD.
wi_batch<- gs_url("https://docs.google.com/spreadsheets/d/1PE5Zl-HUG4Zt0PwSfj-gJRJVbZ__LgH3VuiDW3-BKQg", visibility = "public")
project_batch <- wi_batch %>% gs_read_csv(ws="Projectv1.0")
prj_df_colnames <- project_batch$`Form Value`
prj_df_colnames <- gsub(" ","_",prj_df_colnames)
prj_dff <- data.frame(matrix(ncol = length(prj_df_colnames),nrow=0))
colnames(prj_dff) <- prj_df_colnames 
#prj_dff is now an empty dataframe

#Camerav1.0
cam_batch <- wi_batch %>% gs_read_csv(ws="Camerav1.0")
cam_df_colnames <- cam_batch$`Form Value`
cam_df_colnames <- gsub(" ","_",cam_df_colnames)

#Deploymentv1.0
dep_batch <- wi_batch %>% gs_read_csv(ws="Deploymentv1.0")
dep_df_colnames <- dep_batch$`Form Value`
dep_df_colnames <- gsub(" ","_",dep_df_colnames)

#Imagev1.0
image_batch <- wi_batch %>% gs_read_csv(ws="Imagev1.0")
image_df_colnames <- image_batch$`Form Value`
image_df_colnames <- gsub(" ","_",image_df_colnames)

# write.csv
