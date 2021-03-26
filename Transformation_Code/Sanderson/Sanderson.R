# Sandersson.R Migration Script
# Sanderson File Structure Data Extraction & Migration Tool
# Anthony Ngo. August 2020

#####
# Initializing the Environment

# Clear all variables
rm(list = ls())

# Importing Libraries
library(dplyr)
library(utils)
library(exifr)
library(googlesheets)
library(sp)
library(rworldmap)
source('Transformation_Code/Generic_Functions/wi_functions.R')

######
# Set the following variables to the appropriate values for your project
# See README.md in the Sanderson directory for descriptions of each variable

output_path = "/Users/anthonyngo/Documents/Wildlife_Insights/output/Chile"
project_path = "/Users/anthonyngo/Documents/Wildlife_Insights/Chile"
encoding_path = "/Users/anthonyngo/Documents/Wildlife_Insights/Chile/Taxonomy translations.xlsx"

blank_name = NA
identifier_name= NA

project_id= NA
project_name= NA
project_short_name= NA
project_objectives= NA
project_species= NA
project_sensor_layout= NA
project_bait_use= NA
project_stratification= NA
project_sensor_method= NA
project_blank_images= NA
project_sensor_cluster= NA
project_admin= NA
project_admin_email= NA
project_admin_organization= NA
embargo= NA
metadata_license= NA
image_license= NA


project_species_individual = NA # Optional
project_sensor_layout_targeted_type = NA # Optional
project_bait_type = NA # Optional
project_stratification_type = NA # Optional
project_individual_animals = NA # Optional
initiative_id = NA # Optional

######
# Initializing Batch Uploads
img_count = length(list.files(project_path, recursive=TRUE))

locations <- list.dirs(path=project_path, full.names = FALSE, recursive=FALSE)

proj_bu <- wi_batch_function("Project", 1)
dep_bu <- wi_batch_function("Deployment", length(locations))
img_bu <- wi_batch_function("Image", img_count)
img_i=1

# Pre-Allocating Batch Upload Lists

# Image Batch Upload Lists
project_id_list = character(img_count)
deployment_id_list =character(img_count)
image_id_list =character(img_count)
location_list=character(img_count)
is_blank_list = character(img_count)
identified_by_list = character(img_count)
wi_taxon_id_list = character(img_count)
class_list = character(img_count)
order_list = character(img_count)
family_list = character(img_count)
genus_list = character(img_count)
species_list = character(img_count)
common_name_list = character(img_count)
timestamp_list = character(img_count)
number_of_animals_list = character(img_count)
pb = txtProgressBar(min = 0, max = img_count, initial = 0, char="|", style=3) 

# Deployment Batch Upload Lists
project_id_dep_list = character(length(locations))
deployment_id_dep_list = character(length(locations))
placename_list = character(length(locations))
longitude_list = numeric(length(locations))
latitude_list = numeric(length(locations))
start_date_list = character(length(locations))
end_date_list = character(length(locations))
bait_type_list = character(length(locations))
feature_type_list = character(length(locations))
camera_id_list = character(length(locations))
quiet_period_list = character(length(locations))
camera_functioning_list = character(length(locations))
sensor_height_list = character(length(locations))
sensor_orientation_list = character(length(locations))

#####
# Iterating through Sanderson Directories
# Iterating through the Locations
for (i in 1:length(locations))
{
  loc = locations[i]
  loc_path = paste(project_path, loc, sep="/")
  images = list.files(path=loc_path, recursive = TRUE)
  dates = character()
  
  exif = read_exif(list.files(loc_path, recursive = TRUE, full.names=TRUE))
  
  # Extracting the Deployment Longitude and Latitude from EXIF data if applicable
  long = NA
  lat = NA
  
  if("GPSLongitude" %in% colnames(exif))
  {
    long = unique(exif$GPSLongitude)
  }
  if("GPSLongitude" %in% colnames(exif))
  {
    lat = unique(exif$GPSLatitude)
  }
  
  # Extracting the Deployment Camera Make and Model from EXIF data if applicable
  cam_make = NA
  cam_model = NA
  
  if (unique(exif$Make) != "") {
    cam_make = unique(exif$Make)
  }
  if (unique(exif$Model) != "") {
    cam_model = unique(exif$Model)
  }
  
  # Iterating through the different images in the Location
  for (img_path in images){
    img_path_split = strsplit(img_path, split="/")[[1]]
    
    spec = img_path_split[1]
    cnt = img_path_split[2]
    img = img_path_split[3]
    
    img_s=gsub(".jpg", "", img)
    title_split = strsplit(img_s, " ")[[1]]
    yy = title_split[1]
    mm = title_split[2]
    dd = title_split[3]
    hh = title_split[4]
    mi = title_split[5]
    date = paste(yy, mm, dd, sep="-")
    time = paste(hh,mi,sep=":")
    timestamp = paste(date, time, sep = " ")
    dates = c(dates, timestamp)
    
    project_id_list[img_i]=project_id
    deployment_id_list[img_i]=paste(project_id, loc, sep="_")
    image_id_list[img_i]=paste(project_id, loc,img, sep="_")
    location_list[img_i]=paste(loc, spec, cnt, img, sep = "/")
    if (spec==blank_name){
      is_blank_list[img_i]= "Yes"
    } else {
      is_blank_list[img_i]= "No"
    }
    identified_by_list[img_i]=identifier_name
    wi_taxon_id_list[img_i]=0
    class_list[img_i]=0
    order_list[img_i]=0
    family_list[img_i]=0
    genus_list[img_i]=0
    species_list[img_i]=0
    common_name_list[img_i]=spec
    timestamp_list[img_i]=timestamp
    number_of_animals_list[img_i]=cnt
    img_i = img_i + 1
    setTxtProgressBar(pb,img_i)
  }
  
  project_id_dep_list[i] = project_id
  deployment_id_dep_list[i] = paste(project_id, loc, sep="_")
  placename_list[i] = loc
  
  longitude_list[i] = long
  latitude_list[i] = lat
  
  start_date_list[i] = min(dates)
  end_date_list[i] = max(dates)
  bait_type_list[i] = 0
  feature_type_list[i] = 0
  camera_id_list[i] = paste(cam_make, cam_model, sep="_")
  quiet_period_list[i] = 0
  camera_functioning_list[i] = 0
  sensor_height_list[i] = 0
  sensor_orientation_list[i] = 0
}

rm(exif, yy, mm, dd, mi, date, dates, pb, cam_make, cam_model)

#####
# Filling the Image Batch Upload
img_bu$project_id <- project_id_list 
img_bu$deployment_id <- deployment_id_list
img_bu$image_id <- image_id_list
img_bu$location <- location_list
img_bu$is_blank <- is_blank_list 
img_bu$identified_by <- identified_by_list 
img_bu$wi_taxon_id <- wi_taxon_id_list 
img_bu$class <- class_list 
img_bu$order <- order_list 
img_bu$family <- family_list 
img_bu$genus <- genus_list 
img_bu$species <- species_list 
img_bu$common_name <- common_name_list 
img_bu$timestamp <- timestamp_list 
img_bu$number_of_animals <- number_of_animals_list 

#####
# Filling the Deployment Batch Upload
dep_bu$project_id <- project_id_dep_list
dep_bu$deployment_id <- deployment_id_dep_list
dep_bu$placename <- placename_list
dep_bu$longitude <- longitude_list
dep_bu$latitude <- latitude_list
dep_bu$start_date <- start_date_list
dep_bu$end_date <- end_date_list
dep_bu$bait_type <- bait_type_list
dep_bu$feature_type <- feature_type_list
dep_bu$camera_id <- camera_id_list
dep_bu$quiet_period <- quiet_period_list
dep_bu$camera_functioning <- camera_functioning_list
dep_bu$sensor_height <- sensor_height_list
dep_bu$sensor_orientation <- sensor_orientation_list

#####
# Filling the Project Batch Upload
coords = select(dep_bu, "longitude", "latitude")

# Finding the Country ISO3 Code using Project Longitudes and Latitudes
countriesSP = getMap(resolution='low')
pointsSP = SpatialPoints(coords[!is.na(coords[, 1]), ], proj4string=CRS(proj4string(countriesSP)))  
indices = over(pointsSP, countriesSP)
country_ISO = unique(indices$ISO3)[1] # returns the ISO3 code

rm(pointsSP, coords, indices, countriesSP)

proj_bu$project_id=project_id
proj_bu$project_name=project_name
proj_bu$project_short_name=project_short_name
proj_bu$project_objectives=project_objectives
proj_bu$project_species=project_species
proj_bu$project_sensor_layout=project_sensor_layout
proj_bu$project_bait_use=project_bait_use
proj_bu$project_stratification=project_stratification
proj_bu$project_sensor_method=project_sensor_method
proj_bu$project_blank_images=project_blank_images
proj_bu$project_sensor_cluster=project_sensor_cluster
proj_bu$project_admin=project_admin
proj_bu$project_admin_email=project_admin_email
proj_bu$project_admin_organization=project_admin_organization
proj_bu$country_code=country_ISO
proj_bu$embargo=embargo
proj_bu$metadata_license=metadata_license
proj_bu$image_license=image_license

proj_bu$project_species_individual = project_species_individual # Optional
proj_bu$project_sensor_layout_targeted_type = project_sensor_layout_targeted_type # Optional
proj_bu$project_bait_type = project_bait_type # Optional
proj_bu$project_stratification_type = project_stratification_type # Optional
proj_bu$project_individual_animals = project_individual_animals # Optional
proj_bu$initiative_id = initiative_id # Optional


#####
# Filling the Camera Batch Upload

cam_bu <- wi_batch_function("Camera", length(unique(dep_bu$camera_id)))
cam_bu$project_id = project_id
cam_bu$camera_id = unique(dep_bu$camera_id)
make_model = strsplit(cam_bu$camera_id, split="_")
cam_bu$make = matrix(unlist(make_model), nrow = length(unlist(make_model[1])))[1,]
cam_bu$model = matrix(unlist(make_model), nrow = length(unlist(make_model[1])))[2,]


rm(make_model, camera_functioning_list)

#####
# Translating Project Encoding to WI Taxonomy

# Joining the Common Names for each photocode
raw_species_encoding = select(
  read.csv(encoding_path), -"X", -"X.1")
species_encoding = raw_species_encoding[!duplicated(raw_species_encoding$photocode),]
rm(raw_species_encoding)
species_encoding$common_name = species_encoding$photocode
img_test = left_join(img_bu, species_encoding, "common_name")
img_bu$common_name <-  tolower(img_test$?..Common.Name)

rm(species_encoding, img_test)

# Finding Appropriate WI Taxonomy Data using common name
wi_taxonomy = read.csv("./WI_Global_Taxonomy/WI_Global_Taxonomy.csv")
wi_taxonomy$common_name <- tolower(wi_taxonomy$commonNameEnglish)
wi_info_data=left_join(img_bu, wi_taxonomy, by="common_name")

# Adding WI Taxonomy data
img_bu$wi_taxon_id <- wi_info_data$id
img_bu$class <- wi_info_data$class
img_bu$order <- wi_info_data$order.y
img_bu$family <- wi_info_data$family.y
img_bu$species <- wi_info_data$species.y
img_bu$genus <-  wi_info_data$genus.y
img_bu$species <- wi_info_data$species.y

rm(wi_info_data, wi_taxonomy)

#####
# Writing output CSVs
write.table(proj_bu,file=paste(output_path,"\\","projects.csv",sep=""), row.names = FALSE, sep=",")
write.table(cam_bu,file=paste(output_path,"\\","cameras.csv",sep=""),row.names = FALSE, sep=",")
write.table(dep_bu,file=paste(output_path,"\\","deployments.csv",sep=""),row.names = FALSE, sep=",")
write.table(img_bu,file=paste(output_path,"\\","images.csv",sep=""),row.names = FALSE, sep=",")



