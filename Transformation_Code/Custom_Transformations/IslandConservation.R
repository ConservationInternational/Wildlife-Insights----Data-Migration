rm(list = ls())
# Load libraries
library(dplyr)
library(readxl)
library(tidyverse)
library(googlesheets)
library(lubridate)
source('Transformation_Code/Generic_Functions/wi_functions.R')

images_og <- read_excel("/Users/anthonyngo/Documents/Wildlife_Insights/IslandConservation_files/IC_AI4Earth_2019_compiled_data.xlsx",1)
deployments <- read.csv("/Users/anthonyngo/Documents/Wildlife_Insights/IslandConservation_files/deployments_IC2020.csv",1)
deployments_coord <- read.csv("/Users/anthonyngo/Documents/Wildlife_Insights/IslandConservation_files/deployments_2_DW.csv",1)
projects <- read.csv("/Users/anthonyngo/Documents/Wildlife_Insights/IslandConservation_files/projects_IC2020.csv",1)
species_list <- read.csv("/Users/anthonyngo/Documents/Wildlife_Insights/IslandConservation_files/WildlifeInsightsSpeciesList.csv")
wi_taxa <- read.csv("/Users/anthonyngo/Documents/Wildlife_Insights/Wildlife-Insights----Data-Migration/WI_Global_Taxonomy/WI_Global_Taxonomy.csv")


output_path <- "/Users/anthonyngo/Documents/Wildlife_Insights/output/IslandConservation"
######
# Project Batch Upload Template: Load in the project batch upload template and fill it out.
prj_bu <- wi_batch_function("Project",nrow(projects))

prj_bu$project_id <- projects$project_id
prj_bu$project_name <- projects$project_name
prj_bu$project_short_name <- projects$project_id
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
prj_bu$country_code <- projects$country_code
prj_bu$embargo <- projects$embargo
prj_bu$metadata_license <- projects$metadata_license # Two options: CC0,CC-BY
prj_bu$image_license <- projects$image_license # Three options: CC0,CC-BY,CC-BY-NC


######
# Deployment Batch Upload Template
# Obtain batch upload template
dep_bu <- wi_batch_function("Deployment",nrow(deployments))
# Fill Deployment BU
dep_bu$project_id <-deployments$project_id # If more than one error for now
dep_bu$deployment_id <- deployments$deployment_id

# deployments_coord = select(deployments_coord, "deployment_id", "longitude", "latitude")

dep_bu$placename <- deployments$placename
dep_bu$longitude <- substr(deployments_coord$longitude, 0, 11)
dep_bu$latitude <- substr(deployments_coord$latitude, 0, 11)
dep_bu$start_date <- deployments$start_date
dep_bu$end_date <- deployments$end_date
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
# Image Batch Upload

images_og$Project=vapply(strsplit(images_og$folder,"/"), `[`, 1, FUN.VALUE=character(1))

# Obtaining Count of Objects
images=unique(select(images_og, "filename", "folder", "class", "Project", "reviewer"))
images=drop_na(images, "filename")
image_bu <- wi_batch_function("Image",nrow(images))
occurence_count=as.data.frame(table(images$filename))
names(occurence_count)[names(occurence_count)=="Var1"] = "filename"
images=left_join(images, occurence_count)
# image_bu <- wi_batch_function("Image",nrow(images))

# Mapping IslandConservation encoding to WI Taxonomy
species_list$class = species_list$Label
species_list$project_id=species_list$...Project
images_t=left_join(images, species_list)
images_t=left_join(images_t, wi_taxa, by="id")

# Filling Image BU
image_bu$project_id<- vapply(strsplit(images$folder,"/"), FUN = function(x){
  if(x[1]=="Ngeruktabel_Camera_Study"){
    "Palau"
  } else  if (x[1]=="SantaCruz_Petrel" || x[1]=="Floreana_Petrel") {
    "Floreana"
  } else {
    x[1]
  }
}, FUN.VALUE=character(1))
image_bu$deployment_id <- vapply(strsplit(images$filename,"_"), FUN=function(x){
  
  if (x[1]=="Mona") {
    paste(x[1], "2014_", x[2], sep="")
  } else if (x[1] == "Floreana" || x[1]=="SantaCruz") {
    paste(x[1], "Petrel", x[2], sep="_")
  } else if (x[1]=="Ngeruktabel") {
    paste(x[1], x[2], sep="_")
  } else if (x[1]=="ULITHI"){
    if (x[4]=="PIG" || x[4]=="TRAP"){
      paste(x[3], x[4], sep="_")
    } else if (x[2]=="CAM10" || x[2]=="CAM14" || x[2]=="CAM15") {
      paste(x[2], x[3],sep="")
    } else {
      x[3]
    }
  } else {
    x[2]
  }
}, FUN.VALUE=character(1))
image_bu$image_id <- images$filename
image_bu$location <- paste("gs://anthony_upload", images$folder, images$filename, sep="/")
image_bu$wi_taxon_id <- images_t$uniqueIdentifier
image_bu$class <- images_t$class.y
image_bu$order <- images_t$order
image_bu$family <- images_t$family
image_bu$genus <- images_t$genus
image_bu$species <- images_t$species
image_bu$common_name <- images_t$commonNameEnglish

image_bu$identified_by <- images$reviewer
image_bu$number_of_objects <- images$Freq
image_bu$timestamp <- vapply(strsplit(images$filename, "_"),  FUN=function(x){
  # if (x[1]=="Cabritos" || x[1]=="Ulithi" || x[1]=="Mona" || x[1]=="Floreana_Petrel"){
    if (x[1]!="JFI" && x[1]!="ULITHI"){
      date_str=x[3]
      yyyy=substr(date_str, start = 1, stop = 4)
      mm=substr(date_str, start=5, stop=6)
      dd=substr(date_str, start=7, stop=8)
      date=paste(yyyy,mm,dd, sep="-")
      
      time_str=x[4]
      hh=substr(time_str, start=1, stop=2)
      mm_t=substr(time_str, start=3, stop=4)
      ss=substr(time_str, start=5, stop=6)
      time=paste(hh, mm_t, ss, sep=":")
      timestamp=paste(date, time, sep=" ")
      timestamp
    } else if (x[1]=="JFI"){
      date_str=x[3]
      if (substr(date_str, start=14, stop=14)=="."){
        date_str=paste(substr(date_str, start=1, stop=8), "0", substr(date_str, start=9, stop=13), sep="")
      }
      yyyy=substr(date_str, start = 5, stop = 8)
      mm=substr(date_str, start=3, stop=4)
      dd=substr(date_str, start=1, stop=2)
      date=paste(yyyy,mm,dd, sep="-")
      
      hh=substr(date_str, start=9, stop=10)
      mm_t=substr(date_str, start=11, stop=12)
      ss=substr(date_str, start=13, stop=14)
      time=paste(hh, mm_t, ss, sep=":")
      timestamp=paste(date, time, sep=" ")
      timestamp
    } else if (x[1]=="ULITHI"){
      date_str=x[4]
      if (date_str=="PIG" || date_str=="TRAP"){
        date_str=x[5]
      }
      yyyy=substr(date_str, start = 1, stop = 4)
      mm=substr(date_str, start=5, stop=6)
      dd=substr(date_str, start=7, stop=8)
      date=paste(yyyy,mm,dd, sep="-")
      
      hh=substr(date_str, start=9, stop=10)
      mm_t=substr(date_str, start=11, stop=12)
      ss=substr(date_str, start=13, stop=14)
      time=paste(hh, mm_t, ss, sep=":")
      timestamp=paste(date, time, sep=" ")
      timestamp
    }
},FUN.VALUE=character(1))

#####
# Optional
# image_bu$uncertainty <- images_taxa$Uncertainty 
# image_bu$age <- images_taxa$Age
# image_bu$sex <- images_taxa$Sex
# image_bu$animal_recognizable <- images_taxa$Animal.recognizable
# image_bu$number_of_objects <- images_taxa$Number.of.Animals
# image_bu$individual_id <- images_taxa$Individual.ID
# image_bu$individual_animal_notes <- images_taxa$Individual.Animal.Notes
# image_bu$highlighted <- images_taxa$Image.Favorite
# image_bu$markings <- images_taxa$Color


#####
# Adding start and end dates to deployment bu
dep_bu$start_date = vapply(dep_bu$deployment_id, FUN=function(x){
  dep_images=image_bu[which(image_bu$deployment_id==x),]
  dates=dep_images$timestamp
  start_date=min(dates)
  start_date
}, FUN.VALUE=character(1))

dep_bu$end_date = vapply(dep_bu$deployment_id, FUN=function(x){
  dep_images=image_bu[which(image_bu$deployment_id==x),]
  dates=dep_images$timestamp
  stop_date=max(dates)
  stop_date
}, FUN.VALUE=character(1))

t=image_bu[which(image_bu$deployment_id=="VAQUERIA2013"),]

#####
# Camera Batch Upload
cams = deployments %>%  select("project_id", "camera_id") %>% unique()
cam_bu <- wi_batch_function("Camera", nrow(cams))
cam_bu$project_id <- cams$project_id
cam_bu$camera_id <- cams$camera_id

# Change any NAs to empty values
prj_bu <- prj_bu %>% replace(., is.na(.), "")
cam_bu <- cam_bu %>% replace(., is.na(.), "")
dep_bu <- dep_bu %>% replace(., is.na(.), "")
image_bu <- image_bu %>% replace(., is.na(.), "")

#Splitting batch uploads by project id
for (unique_proj in prj_bu$project_id){
  print(unique_proj)
  prj_bu_sub = prj_bu[prj_bu$project_id == unique_proj,]
  dep_bu_sub = dep_bu[dep_bu$project_id == unique_proj,]
  cam_bu_sub = cam_bu[cam_bu$project_id == unique_proj,]
  image_bu_sub = image_bu[image_bu$project_id == unique_proj,]
  
  project_output_path <- file.path(dirname(output_path), unique_proj)
  dir.create(project_output_path)
  
  
  # Writing output CSVs
  write.table(prj_bu_sub,file=paste(project_output_path,"/projects.csv",sep=""), row.names = FALSE, sep=",")
  write.table(cam_bu_sub,file=paste(project_output_path,"/cameras.csv",sep=""),row.names = FALSE, sep=",")
  write.table(dep_bu_sub,file=paste(project_output_path,"/deployments.csv",sep=""),row.names = FALSE, sep=",")
  write.table(image_bu_sub,file=paste(project_output_path,"/images.csv",sep=""),row.names = FALSE, sep=",")
}







