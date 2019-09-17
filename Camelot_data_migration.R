# Camelot_data_migration.R Eric Fegraus 4/17/2019
# Purpose: Camelot to Wildlife Insights Data Migration Tool
# This will also serve as a template for other data formats.

######
# Clear workspace
rm(list=ls())
# Set your working directory 
setwd("~/work/WildlifeInsights/Wildlife-Insights----Data-Migration")
# Load Libraries
library(dplyr)
library(googlesheets)
library(jsonlite)
source('wi_functions.R')

######
# Load your data and type in any information that cannot be captured from the dataset directly. 
ct_data <- read.csv("data/South Chilcotins Wildlife Suvey.csv")
# Establish any variables needed for each project (i.e. not found in the datafile)

# Taxonomy
# Load in your clean taxonomy. Clean taxononmy is created using the WI_Taxonomy.R file. 
your_taxa <- read.csv("WWF cleaned taxonomy - wwf_tax.csv",colClasses = "character",strip.white = TRUE,na.strings="")
ct_data_taxa <- left_join(ct_data,your_taxa,by="Species")
# Custom for this dataset
ct_data_taxa$wi_common_name[which(is.na(ct_data_taxa$wi_common_name))] <- "Blank"
ct_data_taxa$wi_taxon_id[which(is.na(ct_data_taxa$wi_taxon_id))] <- "f1856211-cfb7-4a5b-9158-c0f72fd09ee6"

######
# Project Batch Upload Template: Load in the project batch upload template and fill it out.
prj_bu <- wi_batch_function("Project",dep_length)

# Many of the project variables may not be found in your dataset. If you can get them from your
# data great! Otherwise type them in here. 
prj_bu$project_id <- unique(ct_data$Survey.ID)
prj_bu$project_name <- "South Chilcotins Wildlife Survey 2018"
prj_bu$project_objectives <- "Comparison of camera trapping vs. eDNA mammal abundance estimates"
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
prj_bu$project_blank_images <- "Yes" # Were blanks removed? Options: Yes, No
prj_bu$project_sensor_cluster <- "No"
prj_bu$project_admin <- "Robin Naidoo"
prj_bu$project_admin_email <- "Robin.Naidoo@wwfus.org"
prj_bu$project_admin_organization <- "WWF" # 
prj_bu$country_code <- "CAN"
prj_bu$embargo <- 0 # 0-24 months
prj_bu$metadata_license <- "CC-BY" # Two options: CC0,CC-BY
prj_bu$image_license <- "CC-BY-NC" # Three options: CC0,CC-BY,CC-BY-NC



######
# Camera Batch Upload Template: Fill in the information relatd to the cameras/sensors used in your project
# First need to get the number of cameras used in the project
num_sensors <- length(unique(ct_data$Camera.ID))
# Get the empty Camera template
cam_bu <- wi_batch_function("Camera",num_sensors)
# Fill out each Camera field
cam_bu$project_id <- unique(prj_bu$project_id) # If more than one error for now
cam_info <- distinct(ct_data_taxa,Camera.ID,Make,Model)
cam_bu$camera_id <- cam_info$Camera.ID
cam_bu$make <- cam_info$Make
cam_bu$model <- cam_info$Model
# If serial number and year purchased are available add them in as well.
cam_bu$serial_number <- MA
cam_bu$year_purchased <- NA
# Notes: We will also try to get information from image EXIF data upon data ingestion into WI. 

######
# Deployment Batch Upload Template: Fill in the information related to each deployment. A deployment is a sensor 
# observing wildlife for some amount of time in a specific location. 
# 
# 1. Establish unique deployments - Should be Site.Name + pair(SessionStart.Date--> Session.End.Date)
ct_data_taxa$deployments <- paste(ct_data_taxa$Site.Name,ct_data_taxa$Session.Start.Date,ct_data_taxa$Session.End.Date,sep="-")
# 2. Create a distinct dataframe based on deployments
dep_temp<-distinct(ct_data_taxa,deployments,.keep_all = TRUE )
# 3. Get the empty deployement dataframe
dep_bu <- wi_batch_function("Deployment",nrow(dep_temp))
# 4. Fill it in
dep_bu$project_id <- unique(prj_bu$project_id) # If more than one error for now
dep_bu$deployment_id <- dep_temp$deployments
dep_bu$placename <- dep_temp$Site.Name
dep_bu$longitude <- dep_temp$Camelot.GPS.Longitude
dep_bu$latitude <- dep_temp$Camelot.GPS.Latitude
dep_bu$start_date <- dep_temp$Session.Start.Date
dep_bu$end_date <- dep_temp$Session.End.Date
dep_bu$event <- NA
dep_bu$array_name <- NA
dep_bu$bait_type <- "None" # Note that if bait was ussed but it was not consistent across all deployments, this is where you enter it. 
    # Logic may be needed to figure out which deployments had bait and which didn't. Similar thing if "bait type" was vaired in deployments.
    # Options: Yes, some, No.  We may need a way to assign this if answer = "some".
dep_bu$bait_description <- NA
dep_bu$feature_type <- "None" # Road paved, Road dirt, Trail hiking, Trail game, Road underpass, Road overpass, Road bridge, Culvert, Burrow, Nest site, Carcass, Water source, Fruiting tree, Other 
dep_bu$feature_type_methodology <- NA
dep_bu$camera_id <- dep_temp$Camera.ID
dep_bu$quiet_period  <- NA
dep_bu$camera_functioning  <- "Camera Functioning"  # Required: Camera Functioning,Unknown Failure,Vandalism,Theft,Memory Card,Film Failure,Camera Hardware Failure,Wildlife Damage
dep_bu$sensor_height  <- "None"
dep_bu$height_other  <- NA
dep_bu$sensor_orientation  <- "Parallel"
dep_bu$orientation_other  <- NA
dep_bu$recorded_by <- NA


######
# Image Batch Upload Template: Fill in the information related to each image
# 
# 1. Do data modifications if needed here.
# Change the file path names for your images. Supply what your original path (original_path) with a replacement string (sub_path)
# original_path <- dQuote(D:\N\personal\investments\3909 Gun Creek Road\research\Camelot_DB\Media)
ct_data_taxa$wi_path <- paste("gs://cameratraprepo-vcm/wwf-bc1",ct_data_taxa$Relative.Path,sep="")

# If all images were identified by one person, set this here. Otherwise comment this out.
image_identified_by <- " Robin Naidoo"
  
# 3. Load in the Image batch upload template
image_bu <- wi_batch_function("Image",nrow(ct_data_taxa))

######
# Image .csv template
image_bu$project_id<- prj_bu$project_id
image_bu$deployment_id <- ct_data_taxa$deployments
image_bu$image_id <- ct_data_taxa$Media.Filename
image_bu$location <- ct_data_taxa$wi_path  # Modify this to let user sub in new path.
image_bu$is_blank[which(ct_data_taxa$wi_common_name== "Blank")] <- "Yes" # Set Blanks to Yes, 
image_bu$is_blank[which(ct_data_taxa$wi_common_name != "Blank")] <- "No"
image_bu$identified_by <- image_identified_by
# Build out more taxonomic information as needed here ASAP. Will be done the week of September 9
image_bu$wi_taxon_id <- ct_data_taxa$wi_taxon_id
image_bu$class <- ct_data_taxa$wi_class
image_bu$order <- ct_data_taxa$wi_order
image_bu$family <- ct_data_taxa$wi_family
image_bu$genus <- ct_data_taxa$wi_genus
image_bu$species <- ct_data_taxa$wi_species
image_bu$common_name <- ct_data_taxa$wi_common_name
image_bu$uncertainty <- NA
image_bu$timestamp <- ct_data_taxa$Date.Time
image_bu$age <- ct_data_taxa$Life.stage
image_bu$sex <- ct_data_taxa$Sex
image_bu$animal_recognizable <- NA
image_bu$number_of_animals <- ct_data_taxa$Sighting.Quantity
image_bu$individual_animal_notes <- NA
image_bu$highlighted <- NA
image_bu$color <- ct_data_taxa$Colour

# Get a clean site name first - no whitespaces
site_name_clean <- gsub(" ","_",prj_bu$project_name)
# Creater the directory
dir.create(path = site_name_clean)
# Change any NAs to emptyp values
prj_bu <- prj_bu %>% replace(., is.na(.), "")
cam_bu <- cam_bu %>% replace(., is.na(.), "")
dep_bu <- dep_bu %>% replace(., is.na(.), "")
image_bu <- image_bu %>% replace(., is.na(.), "")

# Write out the 4 csv files for required for Batch Upload

write.csv(prj_bu,file=paste(site_name_clean,"/","projects.csv",sep=""), row.names = FALSE)
write.csv(cam_bu,file=paste(site_name_clean,"/","cameras.csv",sep=""),row.names = FALSE)
write.csv(dep_bu,file=paste(site_name_clean,"/","deployments.csv",sep=""),row.names = FALSE)
write.csv(image_bu,file=paste(site_name_clean,"/","images.csv",sep=""),row.names = FALSE)

###########
# Misc things we are considering.
# Dataset question: Photo_Type_Identified_by - this is required. Can you find out this person(s)? Alternative is we make it not required.
# Count: This should be one record per species with counts of those animals.
# Date: Need to check WI validation on date types. 


# Read in the Wildlfie Insights Global Taxonomy
# wi_taxa <- fromJSON("https://api.wildlifeinsights.org/api/v1/taxonomy?fields=class,order,family,genus,species,taxonomyType,uniqueIdentifier,commonNameEnglish&page[size]=30000")
# wi_taxa_data <- wi_taxa$data
# wi_taxa_data <- wi_taxa_data %>% replace(., is.na(.), "")
# project_unique_species <- as.data.frame(unique(paste(ct_data$Species,ct_data$Species.Common.Name)))
# # Write out a .csv file that the data provider will use to map into the WI taxonomic authority.

#taxa_data <- distinct(ct_data_taxa,Class,Order,Family,Genus,Species.ID,Species,Species.1)
#write.csv(taxa_data,"taxa_data.csv")
#

# # Set number of rows to full dataset.
# prj_species_df_length <- nrow(project_unique_species)
# #image_dff <- data.frame(matrix(ncol = 1,nrow=prj_species_df_length)) # Add in the colnames: lookup, Species, Common, WI Genus, WI Species, WI Common OR JUST WI TAXONOMY ID
# #colnames(image_dff) <- image_df_colnames 
# write.csv(project_unique_species,file = "WI_batch_species_lookup.csv")
#image_bu$Genus_Species <- ct_data$Species # Lots of quality control to do here.
#image_bu$Species_Common_Name <- ct_data$Species.Common.Name  # Lots of quality control to do here.

