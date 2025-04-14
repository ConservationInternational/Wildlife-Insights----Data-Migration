# Checks that should be done on csv's submitted by users

library(tidyverse)
library(googlesheets4)
library(lubridate)
library(ggmap)

# If you have a key for Google's georeference API add it here
#register_google(key = "")

# Set local directory containing images.csv, cameras.csv, projects.csv and deployments.csv
data_path <- ""

# Load functions - change path depending on were files are
source("Transformation_Code/Generic_Functions/wi_functions.R")
source('Transformation_Code/Generic_Functions/wi_validation.R')


cam_bu <- read_csv(paste0(data_path,"cameras.csv"), show_col_types = FALSE)
dep_bu <- read_csv(paste0(data_path, "deployments.csv"), show_col_types = FALSE)
prj_bu <- read_csv(paste0(data_path, "projects.csv"), show_col_types = FALSE)  
img_bu <- read_csv(paste0(data_path, "images.csv"), show_col_types = FALSE) 

# Get valid project and deployments from WI standard formats
prj_vals <- get_prj_values()
dep_vals <- get_dep_values()

# Missing fields
missing_fields(img_bu, "images")
missing_fields(dep_bu, "deployments")
missing_fields(cam_bu, "cameras")
missing_fields(prj_bu, "projects")

# Missing required values
missing_req_values(img_bu, "images")
missing_req_values(dep_bu, "deployments")
missing_req_values(prj_bu, "projects")
missing_req_values(cam_bu, "cameras")

# Flag extra fields
flag_extra_fields(img_bu, "images")
flag_extra_fields(cam_bu, "cameras")
flag_extra_fields(dep_bu, "deployments")
flag_extra_fields(prj_bu, "projects")

# Checking required values for project and deployments
test_prj_values(prj_bu, prj_vals)
test_dep_values(dep_bu, dep_vals)

# Taxonomy check
taxonomy_check(img_bu)
# Unique image ids
unique_imageids(img_bu)

#Test age variable
test_age(img_bu)

#Test sex variable
test_sex(img_bu)

#Test number of objects variable
test_number_of_objects(img_bu)

# Test uncertainty variable
test_uncertainty(img_bu)

#Duplicate image urls
dup_img_urls(img_bu)

#Duplicate deployment ids
dup_dep_ids(dep_bu)

# Orphaned cameras and deployments
orphaned_cameras(cam_bu, dep_bu)
orphaned_deployments(dep_bu, img_bu)

# Project id matches in all files
projectids_match(img_bu, cam_bu, dep_bu, prj_bu)

# Make sure start_date and end_date are in ymd_hms format
# Date checks for image projects
date_format_check(dep_bu$start_date, "deployment start date...")
date_format_check(dep_bu$end_date, "deployment end date...")
date_format_check(img_bu$timestamp, "timestamp")

# Date checks for sequence projects
date_format_check(img_bu$sequence_start_time, "sequence start time...")



# Validate dep ddtes
validate_dep_dates(dep_bu)

# Are images in deployment date range?
images_in_dep_dt_range(img_bu, dep_bu)

#check lat/lons in dep_bu
check_lat_lon(dep_bu)

# map the deployments - only works if you have an API for google maps
loc <- data.frame(lon = dep_bu$longitude, lat = dep_bu$latitude)
qmplot(lon, lat, data = loc, source = "google", maptype = "hybrid", color = I("yellow"), zoom = 8)

# save clean csvs in a different folder
folder_name <- paste0(data_path, "csvs_ready_for_upload")
dir.create(folder_name, showWarnings = FALSE)

write_csv(img_bu,paste(folder_name, "/images.csv", sep=""), na ="")
write_csv(dep_bu, paste(folder_name, "/deployments.csv", sep=""), na ="")
write_csv(prj_bu,paste(folder_name, "/projects.csv", sep=""), na ="")
write_csv(cam_bu,paste(folder_name, "/cameras.csv", sep=""), na ="")

