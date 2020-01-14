rm(list = ls())
# Load libraries
library(dplyr)
library(readxl)
library(googlesheets)
library(lubridate)
source('wi_functions.R')



cameras <- read.csv("iavh/batch_upload_templates_humboldtv3/cameras.csv")
images <- read.csv("iavh/batch_upload_templates_humboldtv3/images.csv")
projects <- read.csv("iavh/batch_upload_templates_humboldtv3/projects.csv")
deployments <- read.csv("iavh/batch_upload_templates_humboldtv3/deployments.csv")

# Lat/long issues: a 2nd period is include and there are deployments with no lat/long. I've 
# assigned them a lat/long in the raw data file
deployments$lat_end <- str_extract(deployments$Latitude,"[0-9]{3}$")
deployments$lat_final<- str_replace(deployments$Latitude,"\\.[0-9]*$",deployments$lat_end)
#
deployments$long_end <- str_extract(deployments$Longitude,"[0-9]{3}$")
deployments$long_final<- str_replace(deployments$Longitude,"\\.[0-9]*$",deployments$long_end)

paste(deployments$Latitude,deployments$lat_final)
paste(deployments$Longitude,deployments$long_final)

# Projects fix
#prj_bu$metadata_license <- "CC-BY" # Two options: CC0,CC-BY
#prj_bu$image_license <- "CC-BY-NC" # Three options: CC0,CC-BY,CC-BY-NC


# 1. Import the Wildife Insights Global Taxonomy dataset.
wi_taxa <- fromJSON("https://api.wildlifeinsights.org/api/v1/taxonomy?fields=class,order,family,genus,species,taxonomyType,uniqueIdentifier,commonNameEnglish&page[size]=30000")
wi_taxa_data <- wi_taxa$data
wi_taxa_data <- wi_taxa_data %>% replace(., is.na(.), "")
# Write out a .csv file for anyone wanting to look at this in Excel. Feel free to inspect this file and use it 
# however you need to find what matches the taxonomy used in your datasets. We have some tools below to help do this but it is up to 
# you. You can also refernece: https://www.iucnredlist.org/ 
# Check out the data

######
# Project Batch Upload Template: Load in the project batch upload template and fill it out.
prj_bu <- wi_batch_function("Project",nrow(projects))

# Many of the project variables may not be found in your dataset. If you can get them from your
# data great! Otherwise type them in here. 
prj_bu$project_id <- projects$Project.ID
prj_bu$project_name <- projects$Project.Name
prj_bu$project_objectives <- projects$Project.Objectives
prj_bu$project_species <- projects$Project.Species
prj_bu$project_species_individual  <- projects$Project.Species.Individual # NA # If single list out the species (Genus species and comma separated)
prj_bu$project_sensor_layout <- projects$Project.Sensor.Layout #"Systematic" # Options:Systematic, Randomized, Convenience,  Targeted 
prj_bu$project_sensor_layout_targeted_type <-  projects$Project.Sensor.Layout.Targeted.Type
prj_bu$project_bait_use <- projects$Project.Bait.Use # "No"  #Was bait used? Options: Yes,Some,No
prj_bu$project_bait_type <- projects$Project.Bait.Type
prj_bu$project_stratification <- projects$Project.Stratification #"No" #Options: Yes, No
prj_bu$project_stratification_type <- projects$Project.Stratification.Type
prj_bu$project_sensor_method <- projects$Project.Sensor.Method
prj_bu$project_individual_animals <- projects$Project.Individual.Animals #"No" #Options: Yes, No
prj_bu$project_blank_images <- projects$Project.Blank.Images #"Yes" # Were blanks removed? Options: Yes, No
prj_bu$project_sensor_cluster <- projects$Project.Sensor.Cluster
prj_bu$project_admin <- projects$Project.Admin
prj_bu$project_admin_email <- projects$Project.Admin.Email
prj_bu$project_admin_organization <- projects$Project.Admin.Organization
prj_bu$country_code <- projects$Country.Code
prj_bu$embargo <- projects$Embargo.Period
prj_bu$metadata_license <- projects$License.Metadata # Two options: CC0,CC-BY
prj_bu$image_license <- projects$License.Images # Three options: CC0,CC-BY,CC-BY-NC

######
# Camera Batch Upload Template: Fill in the information relatd to the cameras/sensors used in your project
## First need to get the number of cameras used in the project
num_sensors <- nrow(cameras)
cam_bu <- wi_batch_function("Camera",num_sensors)

# Fill out each Camera field
cam_bu$project_id <- cameras$Project.ID # If more than one error for now
cam_bu$camera_id <- cameras$Camera.ID
cam_bu$make <- cameras$Make
cam_bu$model <- cameras$Model
cam_bu$serial_number <- cameras$Serial.Number
cam_bu$year_purchased <- cameras$Year.Purchased

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
dep_bu$project_id <-deployments$Project.ID # If more than one error for now
dep_bu$deployment_id <- deployments$Deployment.ID
dep_bu$placename <- deployments$Deployment.Location.ID
dep_bu$longitude <- deployments$long_final
dep_bu$latitude <- deployments$lat_final
dep_bu$start_date <- deployments$Camera.Deployment.Begin.Date
dep_bu$end_date <- deployments$Camera.Deployment.End.Date
dep_bu$event <- deployments$Event
dep_bu$array_name <- deployments$Array.Name
dep_bu$bait_type <- deployments$Bait.Type #"None" # Note that if bait was ussed but it was not consistent across all deployments, this is where you enter it. 
# Logic may be needed to figure out which deployments had bait and which didn't. Similar thing if "bait type" was vaired in deployments.
# Options: Yes, some, No.  We may need a way to assign this if answer = "some".
dep_bu$bait_description <- deployments$Bait.Description
dep_bu$feature_type <- "None" # Road paved, Road dirt, Trail hiking, Trail game, Road underpass, Road overpass, Road bridge, Culvert, Burrow, Nest site, Carcass, Water source, Fruiting tree, Other 
dep_bu$feature_type_methodology <- NA
dep_bu$camera_id <- deployments$Camera.ID
dep_bu$quiet_period  <- deployments$Quiet.Period.Setting
dep_bu$camera_functioning  <- "Camera Functioning"  # Required: Camera Functioning,Unknown Failure,Vandalism,Theft,Memory Card,Film Failure,Camera Hardware Failure,Wildlife Damage
dep_bu$sensor_height  <- deployments$Height
dep_bu$height_other  <- NA
dep_bu$sensor_orientation  <- "Parallel"
dep_bu$orientation_other  <- NA
dep_bu$recorded_by <- deployments$Recorded.By



######
# Image Batch Upload Template: Fill in the information related to each image
# 
# 1. Import clean taxonomy and joing with the images worksheet.
# Taxonomy
# Load in your clean taxonomy. Clean taxononmy is created using the WI_Taxonomy.R file.
#write.csv(your_taxa,"humbold_taxa.csv",row.names=FALSE)
#your_taxa <- read.csv("humbold_taxa.csv")

#your_taxa_wi <- left_join(your_taxa, wi_taxa_data,by=c("wi_taxon_identifier"= "uniqueIdentifier"))
# Join this into the main images dataframe
#images_wi <- left_join(images,your_taxa_wi,by="wi_taxon_identifier")
# Check the taxa
check <- distinct(images_wi,class,order,family,genus,species,commonNameEnglish,wi_taxon_identifier)
no_taxa <- filter(images, wi_taxon_identifier=="")

images_taxa <- filter(images, wi_taxon_identifier != "")

#Create a join column that accounts for both species and non-species labels from your 
#your_taxa$join_taxa <- your_taxa$original_gs
# Add in the non-species original names
#your_taxa$join_taxa[which(!is.na(your_taxa$Your_nonspecies))] <- your_taxa$Your_nonspecies[which(!is.na(your_taxa$Your_nonspecies))]
# Do the same with the images dataframe
#images$join_taxa <- images$`Genus Species`
#images$join_taxa[which(is.na(images$join_taxa))] <- images$`Photo Type`[which(is.na(images$join_taxa))]
# Join the WI taxonomy back into the images dataframe.
#images_taxa <- left_join(images,your_taxa,by="join_taxa")
# Check the taxa
#check <- distinct(images_taxa,class,order,family,genus,species,commonNameEnglish,uniqueIdentifier)
#no_wi <- filter(images_taxa, is.na(uniqueIdentifier))
  
# 3. Load in the Image batch upload template
image_bu <- wi_batch_function("Image",nrow(images_taxa))

######
# Image .csv template
image_bu$project_id<- images_taxa$Project.ID
image_bu$deployment_id <- images_taxa$Deployment.ID
image_bu$image_id <- images_taxa$Image.ID
image_bu$location <- images_taxa$Location
image_bu$is_blank <- images_taxa$Blank
image_bu$wi_taxon_id <- images_taxa$wi_taxon_identifier
image_bu$class <- images_taxa$Class
image_bu$order <- images_taxa$Order
image_bu$family <- images_taxa$Family
image_bu$genus <- images_taxa$Genus
image_bu$species <- images_taxa$Species
image_bu$common_name <- images_taxa$Species.Common.Name
image_bu$uncertainty <- images_taxa$Uncertainty
image_bu$timestamp <- ymd_hms(images_taxa$Date_Time.Captured)
image_bu$age <- images_taxa$Age
image_bu$sex <- images_taxa$Sex
image_bu$animal_recognizable <- images_taxa$Animal.recognizable
image_bu$number_of_animals <- images_taxa$Number.of.Animals
image_bu$individual_id <- images_taxa$Individual.ID
image_bu$individual_animal_notes <- images_taxa$Individual.Animal.Notes
image_bu$highlighted <- images_taxa$Image.Favorite
image_bu$color <- images_taxa$Color
image_bu$identified_by <- images_taxa$Photo.Type.Identified.by


# Create the directory
#dir.create(path = site_name_clean)
# Change any NAs to emptyp values
prj_bu <- prj_bu %>% replace(., is.na(.), "")
cam_bu <- cam_bu %>% replace(., is.na(.), "")
dep_bu <- dep_bu %>% replace(., is.na(.), "")
image_bu <- image_bu %>% replace(., is.na(.), "")

# Write out the 4 csv files for required for Batch Upload
write.csv(prj_bu,file="iavh/projects.csv", row.names = FALSE)
write.csv(cam_bu,file="iavh/cameras.csv",row.names = FALSE)
write.csv(dep_bu,file="iavh/deployments.csv",row.names = FALSE)
write.csv(image_bu,file="iavh/images.csv",row.names = FALSE)
