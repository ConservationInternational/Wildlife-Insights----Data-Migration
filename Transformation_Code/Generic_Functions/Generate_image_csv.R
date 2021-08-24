# This script generates an images.csv batch upload template from a project directory.
# Each project directory has subfolders for deployments.
# Each deployment subfolder has images associated with that deployment. 

# TODO: Required installations:
# 1.Exif tool: https://exiftool.org/
# 2. Perl: https://strawberryperl.com/
# 3. Exifr R package: install(exifr)

rm(list = ls())
library(exifr)
library(tidyverse)
library(googlesheets4)

# TODO: Change this path to point to wi_functions.R on your machine. 
source('C:\\Users\\12147\\Documents\\Wildlife-Insights----Data-Migration\\Transformation_Code\\Generic_Functions\\wi_functions.R')

# TODO: Provide local folder path and project id
prj_folder = 'C:\\Users\\12147\\AppData\\Local\\Google\\Cloud SDK\\EBM2010'
project_id = 'EBM2010'

dep_ids = list.dirs(path = prj_folder, full.names = FALSE, recursive = FALSE)
images = list.files(path = prj_folder, full.names = FALSE, recursive = TRUE)
image_bu <- wi_batch_function("Image",length(images))
image_bu$project_id = project_id
row_id = 0

for(dep in dep_ids){
  
  subf = paste(prj_folder,"\\",dep, sep="")
  image_ids = list.files(subf, full.names = FALSE, recursive = FALSE)
  
  for(image in image_ids){
    location = paste(subf, "\\", image,  sep="")
    exif <- read_exif(location)
    
    image_bu[row_id, "deployment_id"] = dep
    image_bu[row_id, "timestamp"] = exif["DateTimeOriginal"]
    image_bu[row_id, "location"] = location
    image_bu[row_id, "image_id"] = image
    
    row_id = row_id+1
  }
}

# Write images.csv to working directory. 
write_csv(image_bu, "images.csv", na="")