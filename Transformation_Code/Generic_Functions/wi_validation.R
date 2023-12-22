# This script contains functions to validate batch upload templates at 
# a basic level.

library(tidyverse)
library(googlesheets4)
library(jsonlite)
library(dplyr)
library(lubridate)
library(purrr)

source('Wildlife-Insights----Data-Migration/Transformation_Code/Generic_Functions/wi_functions.R')

# Flag missing fields. 
missing_fields <- function(df, type){
  dictionary <- wi_batch_function(type,1)
  setdiff(colnames(dictionary), colnames(df))
  
  if (identical(setdiff(colnames(dictionary), colnames(df)),character(0))) {
    print(paste("All fields present in", type, "template."))} 
  else { print(paste("ERROR -- following fields missing from", type))
    print(setdiff(colnames(dictionary), colnames(df)))}

}

# Flag required fields with missing values. 
missing_req_values <- function(df, type){
  dictionary <- wi_batch_function_req(type,1)
  fields_req_vals = colnames(dictionary)
  msg = paste0(type, ".csv - following fields have missing values:")
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
    
    if (!identical(setdiff(img_bu$deployment_id, dep_bu$deployment_id),
                   character(0)))
    {
      print("ERROR -- Orphaned deployments in images.csv")
      print(setdiff(img_bu$deployment_id, dep_bu$deployment_id))
    }
    if (!identical(setdiff(dep_bu$deployment_id, img_bu$deployment_id),
                   character(0)))
    { 
      print("ERROR -- Orphaned deployments in deployments.csv")
      print(setdiff(dep_bu$deployment_id, img_bu$deployment_id))
    }
  }
}

# Flag orphaned camera ids. 
orphaned_cameras <- function(cam_bu, dep_bu) {
  if (identical(as.character(setdiff(cam_bu$camera_id, dep_bu$camera_id)), character(0))
      &&
      identical(as.character(setdiff(dep_bu$camera_id, cam_bu$camera_id)), character(0)))
  {
    print('No orphaned cameras in Cameras.csv and Deployments.csv')
  }
  else {
    if (!identical(as.character(setdiff(cam_bu$camera_id, dep_bu$camera_id)), character(0))){
      print("ERROR -- Orphaned cameras in cameras.csv.")
      print(as.character(setdiff(cam_bu$camera_id, dep_bu$camera_id)))  
    }
    if(!identical(setdiff(dep_bu$camera_id, cam_bu$camera_id), character(0))){
      print("ERROR -- Orphaned cameras in deployments.csv.")
      print(as.character(setdiff(dep_bu$camera_id, cam_bu$camera_id)))
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
    print(setdiff(img_bu$wi_taxon_id, taxons$wi_taxon_id))
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
  print(paste(nrow(img_bu_outr),"out of" , nrow(img_bu), "images are not in range."))
    by_dep <- img_bu_outr %>% 
      group_by(deployment_id) %>% 
      summarize(images_out_of_range = n())
    
    by_img <- img_bu_outr %>% 
      select(deployment_id, image_id)
    
  print("Number of images by deployment not in deployment date range:")
  print(by_dep , n =nrow(by_dep))
  
  print("Detail of images not in deployment date range:")
  print(by_img , n =nrow(by_img))
  write.csv(by_dep, "images out range by deployment.csv")
  write.csv(by_img, "images out of range.csv")
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
  errors = nrow(img_bu) - nrow(distinct(img_bu, image_id, common_name))
  if(errors == 0 ){
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

dup_dep_ids <- function(dep_bu){
  
  if(nrow(dep_bu[duplicated(dep_bu$deployment_id),]) > 0){
    print(paste("Error --",nrow(dep_bu[duplicated(dep_bu$deployment_id),]) ,"deployment ids are duplicates."))
  }
  else
    print("Deployment ids are unique.")

}

projectids_match <- function(img_bu, cam_bu, dep_bu, prj_bu){
  i_pid = unique(img_bu$project_id)
  c_pid = unique(cam_bu$project_id)
  d_pid = unique(dep_bu$project_id)
  p_pid = unique(prj_bu$project_id)
  if(i_pid == p_pid && c_pid == p_pid && d_pid == p_pid){
    print("Project ids ok.")
  }
  else{
    print("ERROR -- Project ids dont match.")
  }
}

#Test whether values in the required variables in the projects.csv file match the WI standard. Need to run the get_prj_values() function first and store the result in variable prj_vals

test_prj_values <- function(df, prj_vals) {
  prj_test <- df |> select(names(prj_vals))
  results_test <- map2(prj_test, prj_vals, f_test)
  if(length(which(results_test == FALSE)) == 0)
    print("Values are ok.")
  else
    paste(names(which(results_test == FALSE)), "has an invalid value!")
}

#Test whether values in the required variables in the deployments.csv file match the WI standard. Need to run the get_dep_values() function first and store the result in variable dep_vals

test_dep_values <- function(df, dep_vals) {
  dep_test <- dep_bu|> select(names(dep_vals))
  dep_test <- lapply(dep_test, unique)
  results_test <- map2(dep_test, dep_vals, f_test)
  results_test <- unlist(results_test)
  if(length(which(results_test == FALSE)) == 0)
    print("Values are ok.")
  else
    paste(names(which(results_test == FALSE)), "has an invalid value!")
}

# Runs all the validations in this script. 
# Errors messages are printed to console.
basic_validation <- function(img_bu, cam_bu, dep_bu, prj_bu){
  missing_fields(img_bu, "images")
  missing_fields(cam_bu, "cameras")
  missing_fields(dep_bu, "deployments")
  missing_fields(prj_bu, "projects")
  
  flag_extra_fields(img_bu, "images")
  flag_extra_fields(cam_bu, "cameras")
  flag_extra_fields(dep_bu, "deployments")
  flag_extra_fields(prj_bu, "projects")
  
  missing_req_values(img_bu, "images")
  missing_req_values(cam_bu, "cameras")
  missing_req_values(dep_bu, "deployments")
  missing_req_values(prj_bu, "projects")
  
  taxonomy_check(img_bu)
  unique_imageids(img_bu)
  dup_img_urls(img_bu)
  dup_dep_ids(dep_bu)
  
  orphaned_cameras(cam_bu, dep_bu)
  orphaned_deployments(dep_bu, img_bu)
  
  projectids_match(img_bu, cam_bu, dep_bu, prj_bu)
  
  date_format_check(dep_bu$start_date, "deployment start date...")
  date_format_check(dep_bu$end_date, "deployment end date...")
  date_format_check(img_bu$timestamp, "image timestamp...")
  if(prj_bu$project_type == "Sequence"){
  date_format_check(img_bu$sequence_start_time, "sequence start time...")}
  validate_dep_dates(dep_bu)
  images_in_dep_dt_range(img_bu, dep_bu)
}