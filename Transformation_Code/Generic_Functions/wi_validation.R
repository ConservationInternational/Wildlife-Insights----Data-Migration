# This script contains functions to validate batch upload templates at 
# a basic level.

library(tidyverse)
library(googlesheets4)
library(jsonlite)
library(dplyr)
library(lubridate)
source('~/Wildlife-Insights----Data-Migration/Transformation_Code/Generic_Functions/wi_functions.R')

# Flag missing fields. 
missing_fields <- function(df, type){
  dictionary <- wi_batch_function(type,1)
  setdiff(colnames(dictionary), colnames(df))
  
  if (identical(setdiff(colnames(dictionary), colnames(df)),character(0))) {
    print(paste("All fields present in", type, " template."))} 
  else { print(paste("ERROR -- following fields missing from", type))
    print(setdiff(colnames(dictionary), colnames(df)))}

}

# Flag required fields with missing values. 
missing_req_values <- function(df, type){
  print(type)
  dictionary <- wi_batch_function_req(type,1)
  fields_req_vals = colnames(dictionary)
  msg = paste0(type, "s.csv - following fields have missing values:")
  i = 0
  for(field in fields_req_vals){ 
    if(sum(is.na(df[, field])) > 0){
      msg = append(msg, field)
      i = i+1 }
  }
  if(i > 0){
    print(msg) } 
  else{ print(paste(type, "s.csv has all the required values.", sep=""))
  }
}

# Flag orphaned deployment ids. 
orphaned_deployments <- function(dep_bu, img_bu) {
  # This should return an empty character
  if (identical(setdiff(img_bu$deployment_id, dep_bu$deployment_id),
                character(0))
      &&
      identical(setdiff(dep_bu$deployment_id, img_bu$deployment_id),
                character(0)))
  {
    print('No orphaned deployments in Images.csv and Deployments.csv')
  }
  else {
    print("ERROR -- Orphaned deployments")
    if (!identical(setdiff(img_bu$deployment_id, dep_bu$deployment_id),
                   character(0)))
    {
      print(setdiff(img_bu$deployment_id, dep_bu$deployment_id))
    }
    if (!identical(setdiff(dep_bu$deployment_id, img_bu$deployment_id),
                   character(0)))
    {
      print(setdiff(dep_bu$deployment_id, img_bu$deployment_id))
    }
  }
}

# Flag orphaned camera ids. 
orphaned_cameras <- function(cam_bu, dep_bu) {
  if (identical(setdiff(cam_bu$camera_id, dep_bu$camera_id), character(0))
      &&
      identical(setdiff(dep_bu$camera_id, cam_bu$camera_id), character(0)))
  {
    print('No orphaned cameras in Cameras.csv and Deployments.csv')
  }
  else {
    print("ERROR -- Orphaned cameras")
    
    if (!identical(setdiff(cam_bu$camera_id, dep_bu$camera_id), character(0))){
    
      print(setdiff(cam_bu$camera_id, dep_bu$camera_id))  
    }
    if(!identical(setdiff(dep_bu$camera_id, cam_bu$camera_id), character(0))){
      print(setdiff(dep_bu$camera_id, cam_bu$camera_id))      
    }
  }
}

# Verify taxonomies against the WI taxonomy API.
taxonomy_check <- function(img_bu){
  taxons = wi_get_taxons()
  if (identical(setdiff(img_bu$wi_taxon_id, taxons$wi_taxon_id),character(0))) {
    print('Taxonomies match')
  } else {
    print("ERROR -- Taxonomies do not match")
  }
}

# Verify if all deployments end dates are after start dates. 
validate_dep_dates <- function(dep_bu) {
  
n_format_errors = sum(!grepl("\\d{4}\\-\\d{2}\\-\\d{2} \\d{2}\\:\\d{2}\\:\\d{2}", 
                             dep_bu$start_date))
                  + sum(!grepl("\\d{4}\\-\\d{2}\\-\\d{2} \\d{2}\\:\\d{2}\\:\\d{2}", 
                             dep_bu$start_date))
  if(n_format_errors > 0){
    print("Please correct the date format of deployment start and end dates and then validate their date range.")
  }
  else
  {
  count = 0
  for(i in 1:nrow(dep_bu)){
    date_diff = difftime(strptime(dep_bu$end_date[i], "%Y-%m-%d %H:%M:%S"),
                         strptime(dep_bu$start_date[i], "%Y-%m-%d %H:%M:%S"),
                         units="mins")
    if(date_diff < 0){ 
      print(paste('deployment id: ',dep_bu$deployment_id[i], ' is faulty'))
      count = count + 1}
  }
  
  if(count == 0) print("All deployment dates are valid.")
  }
}

# For each deployment, verify if images are within the deployment date range. 
# Returns the image template with a TRUE/FALSE flag for each image. 
images_in_dep_dt_range <- function(img_bu, dep_bu){
  
  img_dep_comb <- left_join(img_bu, dep_bu, by = "deployment_id")
  img_dep_comb$in_range = ymd_hms(img_dep_comb$timestamp) %within% interval(ymd_hms(img_dep_comb$start_date), 
                  ymd_hms(img_dep_comb$end_date))
  img_bu_outr = filter(img_dep_comb, in_range == 'FALSE')

  if(nrow(img_bu_outr)> 0){
  print(paste(nrow(img_bu_outr),"out of" , nrow(img_bu), "images are not in deployment date range."))
  print("Number of images not in deployment date range(by deployment id): ")
        print(table(img_bu_outr$deployment_id))
  }
}

# Verify if dates are in the the YYYY-MM-DD hh:mm:ss format.
date_format_check <- function(dates, type){
  print(paste("Checking date formats for", type))
  n_format_errors = sum(!grepl("\\d{4}\\-\\d{2}\\-\\d{2} \\d{2}\\:\\d{2}\\:\\d{2}", dates))
  # n_format_errors = n_format_errors + sum(nchar(dates) != 19)
  if(n_format_errors > 0){
    print(paste("ERROR -- ", n_format_errors, "date(s) have errors."))
  }
  else {
    print("No errors in date format.")
  }
}

# Verify if all images have unique ids.
unique_imageids <- function(img_bu){
  errors = nrow(img_bu) - length(unique(img_bu$image_id))
  if(errors == 0){
    print("Images.csv has unique image ids.")
  }
  else {
    print(paste("ERROR -- Images.csv has", errors,"duplicate image ids."))
    }
}

dup_img_urls <- function(img_bu){
  
  if(nrow(img_bu[duplicated(img_bu$location),]) > 0){
    print(paste("Error --",nrow(img_bu[duplicated(img_bu$location),]) ,"image URLs are duplicate."))
  }
  else
    print("Image URLs are unique.")

}

projectids_match <- function(img_bu, cam_bu, dep_bu, prj_bu){
  i_pid = img_bu$project_id
  c_pid = cam_bu$project_id
  d_pid = dep_bu$project_id
  p_pid = prj_bu$project_id
  if(i_pid == p_pid && c_pid == p_pid && d_pid == p_pid){
    print("Project ids ok.")
  }
  else{
    print("ERROR -- Project ids dont match.")
  }
}

# Runs all the validations in this script. 
# Errors messages are printed to console.
basic_validation <- function(img_bu, cam_bu, dep_bu, prj_bu){
  missing_fields(img_bu, "Image")
  missing_fields(cam_bu, "Camera")
  missing_fields(dep_bu, "Deployment")
  missing_fields(prj_bu, "Project")
  
  flag_extra_fields(img_bu, "Image")
  flag_extra_fields(cam_bu, "Camera")
  flag_extra_fields(dep_bu, "Deployment")
  flag_extra_fields(prj_bu, "Project")
  
  missing_req_values(img_bu, "Image")
  missing_req_values(cam_bu, "Camera")
  missing_req_values(dep_bu, "Deployment")
  missing_req_values(prj_bu, "Project")
  
  taxonomy_check(img_bu)
  unique_imageids(img_bu)
  dup_img_urls(img_bu)
  
  orphaned_cameras(cam_bu, dep_bu)
  orphaned_deployments(dep_bu, img_bu)
  
  projectids_match(img_bu, cam_bu, dep_bu, prj_bu)
  
  date_format_check(dep_bu$start_date, "deployment start date.")
  date_format_check(dep_bu$end_date, "deployment end date.")
  date_format_check(img_bu$timestamp, "image timestamp.")
  
  validate_dep_dates(dep_bu)
  images_in_dep_dt_range(img_bu, dep_bu)


# Flag missing fields. 
missing_fields <- function(df, type){
  dictionary <- wi_batch_function(type,1)
  setdiff(colnames(dictionary), colnames(df))
  
  if (identical(setdiff(colnames(dictionary), colnames(df)),character(0))) {
    print(paste("All fields present in", type, " template."))} 
  else { print(paste("ERROR -- following fields missing from", type))
    print(setdiff(colnames(dictionary), colnames(df)))}

}

# Flag required fields with missing values. 
missing_req_values <- function(df, type){
  print(type)
  dictionary <- wi_batch_function_req(type,1)
  fields_req_vals = colnames(dictionary)
  msg = paste0(type, "s.csv - following fields have missing values:")
  i = 0
  for(field in fields_req_vals){ 
    if(sum(is.na(df[, field])) > 0){
      msg = append(msg, field)
      i = i+1 }
  }
  if(i > 0){
    print(msg) } 
  else{ print(paste(type, "s.csv has all the required values.", sep=""))
  }
}

# Flag orphaned deployment ids. 
orphaned_deployments <- function(dep_bu, img_bu){
  # This should return an empty character
  if (identical(setdiff(img_bu$deployment_id,dep_bu$deployment_id),character(0))) {
    print('No orphaned deployments in Images.csv and Deployments.csv')} 
  else { print("ERROR -- Orphaned deployments")
    print(setdiff(img_bu$deployment_id,dep_bu$deployment_id))}
}

# Flag orphaned camera ids. 
orphaned_cameras <- function(cam_bu, dep_bu){
  if (identical(setdiff(cam_bu$camera_id,dep_bu$camera_id),character(0)) 
    && identical(setdiff(dep_bu$camera_id,cam_bu$camera_id),character(0))) 
  { print('No orphaned cameras in Cameras.csv and Deployments.csv')} 
  else { print("ERROR -- Orphaned cameras")
    print(setdiff(cam_bu$camera_id,dep_bu$camera_id))
    print(setdiff(dep_bu$camera_id,cam_bu$camera_id))}
}

# Verify taxonomies against the WI taxonomy API.
taxonomy_check <- function(images){
  wi_taxa_data = wi_get_taxons()
  
  # Get unique list of taxa
  taxa = distinct(images,wi_taxon_id)
  
  taxa$wi_taxon_id %in% wi_taxa_data$uniqueIdentifier
  intersect(taxa$wi_taxon_id,wi_taxa_data$uniqueIdentifier)
  no_match = setdiff(taxa$wi_taxon_id,wi_taxa_data$uniqueIdentifier)
  
  if (identical(setdiff(taxa$wi_taxon_id,wi_taxa_data$uniqueIdentifier),character(0))) {
    print('Taxanomies match')
  } else {
    print("ERROR -- Taxonomies do not match")
  }
}

# Verify if all deployments end dates are after start dates. 
validate_dep_dates <- function(dep_bu) {
  count = 0
  for(i in 1:nrow(dep_bu)){
    date_diff = difftime(strptime(dep_bu$end_date[i], "%Y-%m-%d %H:%M:%S"),
                         strptime(dep_bu$start_date[i], "%Y-%m-%d %H:%M:%S"),
                         units="mins")
    if(date_diff < 0){ 
      print(paste('deployment id: ',dep_bu$deployment_id[i], ' is faulty'))
      count = count + 1}
  }
  
  if(count == 0) print("All deployment dates are valid.")
}

# For each deployment, verify if images are within the deployment date range. 
# Returns the image template with a TRUE/FALSE flag for each image. 
images_in_dep_dt_range <- function(img_bu, dep_bu){
  
  img_dep_comb <- left_join(img_bu, dep_bu, by = "deployment_id")
  img_dep_comb$in_range = ymd_hms(img_dep_comb$timestamp) %within% interval(ymd_hms(img_dep_comb$start_date), 
                  ymd_hms(img_dep_comb$end_date))
  print("Images not in deployment date range: ")
  img_bu_outr = filter(img_dep_comb, in_range == 'FALSE')
  print(table(img_bu_outr$deployment_id))
  return(table(img_dep_comb$in_range))
}

# Verify if dates are in the the YYYY-MM-DD hh:mm:ss format.
date_format_check <- function(dates){
  n_format_errors = sum(!grepl("\\d{4}\\-\\d{2}\\-\\d{2} \\d{2}\\:\\d{2}\\:\\d{2}", dates))
  print(paste(n_format_errors, "date(s) have errors."))
}

# Runs all the validations in this script. 
# Errors messages are printed to console.
basic_validation <- function(img_bu, cam_bu, dep_bu, prj_bu){
  missing_fields(img_bu, "Image")
  missing_fields(cam_bu, "Camera")
  missing_fields(dep_bu, "Deployment")
  missing_fields(prj_bu, "Project")
  
  missing_req_values(img_bu, "Image")
  missing_req_values(cam_bu, "Camera")
  missing_req_values(dep_bu, "Deployment")
  missing_req_values(prj_bu, "Project")
  
  taxonomy_check(img_bu)
  
  orphaned_cameras(cam_bu, dep_bu)
  orphaned_deployments(dep_bu, img_bu)
  
  date_format_check(dep_bu$start_date)
  date_format_check(dep_bu$end_date)
  date_format_check(img_bu$timestamp)

  validate_dep_dates(dep_bu)
  images_in_dep_dt_range(img_bu, dep_bu)}
}