rm(list = ls())
# Load libraries
library(dplyr)
library(readxl)
library(googlesheets)
library(lubridate)
library(readxl)
source('Transformation_Code/Generic_Functions/wi_functions.R')

images <- read_excel("C:/Users/wolf1/OneDrive/Documents/Wildlife Insights/IslandConservation_files/IC_AI4Earth_2019_compiled_data.xlsx",1)
deployments <- read.csv("C:/Users/wolf1/OneDrive/Documents/Wildlife Insights/IslandConservation_files/deployments_IC2020.csv",1)
# cameras <- read_excel("C:/Users/wolf1/OneDrive/Documents/Wildlife Insights/IslandConservation_files/IC_AI4Earth_2019_compiled_data.xlsx",1)
projects <- read.csv("C:/Users/wolf1/OneDrive/Documents/Wildlife Insights/IslandConservation_files/projects_IC2020.csv",1)
species_list <- read.csv("C:/Users/wolf1/OneDrive/Documents/Wildlife Insights/IslandConservation_files/WildlifeInsightsSpeciesList.csv")
wi_taxa <- read.csv("C:\\Users\\wolf1\\OneDrive\\Documents\\Wildlife Insights\\Wildlife-Insights----Data-Migration\\WI_Global_Taxonomy\\WI_Global_Taxonomy.csv")
######
# Project Batch Upload Template: Load in the project batch upload template and fill it out.
prj_bu <- wi_batch_function("Project",nrow(projects))

# Many of the project variables may not be found in your dataset. If you can get them from your
# data great! Otherwise type them in here. 
prj_bu$project_id <- projects$project_id
prj_bu$project_name <- projects$Project_name
prj_bu$project_objectives <- projects$project_objectives
prj_bu$project_species <- projects$project_species
prj_bu$project_species_individual  <- projects$project_species_individual # NA # If single list out the species (Genus species and comma separated)

prj_bu$project_sensor_layout <- projects$project_sensor_layout #"Systematic" # Options:Systematic, Randomized, Convenience,  Targeted 
prj_bu$project_sensor_layout_targeted_type <-  projects$project_sensor_layout_targeted_type
prj_bu$project_bait_use <- projects$project_bait_use # "No"  #Was bait used? Options: Yes,Some,No
prj_bu$project_bait_type <- projects$project_bait_type
prj_bu$project_stratification <- projects$project_stratification #"No" #Options: Yes, No
prj_bu$project_stratification_type <- projects$project_stratification_type
prj_bu$project_sensor_method <- projects$project_sensor_method
prj_bu$project_individual_animals <- projects$project_individual_animals #"No" #Options: Yes, No
prj_bu$project_blank_images <- projects$project_blank_images #"Yes" # Were blanks removed? Options: Yes, No
prj_bu$project_sensor_cluster <- projects$project_sensor_cluster
prj_bu$project_admin <- projects$project_admin
prj_bu$project_admin_email <- projects$project_admin_email
prj_bu$project_admin_organization <- projects$project_admin_organization
prj_bu$country_code <- projects$country_code
prj_bu$embargo <- projects$embargo
prj_bu$metadata_license <- projects$metadata_license # Two options: CC0,CC-BY
prj_bu$image_license <- projects$image_license # Three options: CC0,CC-BY,CC-BY-NC


######
# Deployment Batch Upload Template: Fill in the information related to each deployment. A deployment is a sensor 
# observing wildlife for some amount of time in a specific location. 
# 
# 1. Establish unique deployments - Should be Site.Name + pair(SessionStart.Date--> Session.End.Date)
#ct_data_taxa$deployments <- paste(ct_data_taxa$Site.Name,ct_data_taxa$Session.Start.Date,ct_data_taxa$Session.End.Date,sep="-")
# 2. Create a distinct dataframe based on deployments
#dep_temp<-distinct(ct_data_taxa,deployments,.keep_all = TRUE )
# 3. Get the empty deployement dataframe
dep_bu <- wi_batch_function("Deployment",nrow(deployments))
# 4. Fill it in
dep_bu$project_id <-deployments$project_id # If more than one error for now
dep_bu$deployment_id <- deployments$deployment_id
dep_bu$placename <- deployments$placename
dep_bu$longitude <- deployments$longitude
dep_bu$latitude <- deployments$latitude
dep_bu$start_date <- deployments$start_date
dep_bu$end_date <- deployments$end_date
dep_bu$event <- deployments$event
dep_bu$array_name <- deployments$array_name
dep_bu$bait_type <- deployments$bait_type
dep_bu$bait_description <- deployments$bait_description
dep_bu$feature_type <- deployments$feature_type 
dep_bu$feature_type_methodology <- deployments$feature_type_methodology
dep_bu$camera_id <- deployments$camera_id
dep_bu$quiet_period  <- deployments$quiet_period
dep_bu$camera_functioning  <- deployments$camera_functioning  
dep_bu$sensor_height  <- deployments$sensor_height
dep_bu$height_other  <- deployments$height_other
dep_bu$sensor_orientation  <- deployments$sensor_orientation
dep_bu$orientation_other  <- deployments$orientation_other
dep_bu$recorded_by <- deployments$recorded_by

######
image_bu <- wi_batch_function("Image",nrow(images))

######
# Image .csv template



species_list$class = species_list$Label
species_list$project_id=species_list$ï..Project
images$project_id=vapply(strsplit(images$folder,"/"), `[`, 1, FUN.VALUE=character(1))

# Extract Date Function

vapply(strsplit(images$filename, "_"), `[`, 4, FUN.VALUE=character(1))


image_bu$project_id<- vapply(strsplit(images$folder,"/"), `[`, 1, FUN.VALUE=character(1))
image_bu$deployment_id <- vapply(strsplit(images$folder,"/"), `[`, 3, FUN.VALUE=character(1))
image_bu$image_id <- images$filename
image_bu$location <- paste(images$folder, images$filename, sep="/")
image_bu$wi_taxon_id <- images_t$id
image_bu$class <- images_t$class.y
image_bu$order <- images_t$order
image_bu$family <- images_t$family
image_bu$genus <- images_t$genus
image_bu$species <- images_t$species
image_bu$common_name <- images_t$commonNameEnglish
# image_bu$uncertainty <- images_taxa$Uncertainty
# image_bu$timestamp <- ymd_hms(images_taxa$Date_Time.Captured)
# image_bu$age <- images_taxa$Age
# image_bu$sex <- images_taxa$Sex
# image_bu$animal_recognizable <- images_taxa$Animal.recognizable
# image_bu$number_of_objects <- images_taxa$Number.of.Animals
# image_bu$individual_id <- images_taxa$Individual.ID
# image_bu$individual_animal_notes <- images_taxa$Individual.Animal.Notes
# image_bu$highlighted <- images_taxa$Image.Favorite
# image_bu$markings <- images_taxa$Color
image_bu$identified_by <- images$reviewer



