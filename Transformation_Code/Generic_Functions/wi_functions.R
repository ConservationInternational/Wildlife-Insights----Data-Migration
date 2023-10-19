# wi_functions.R Eric Fegraus 09-05-2019
# Purpose: Key functions used to help migrate data into the Wilidlife Insights
# Batch Upload formats. 
##############################################################################
# Function: wi_batch_function
# Access the Wildlife Insights Batch Upload templates and return
# empty data frames for Project, Camera, Deployment and Images
# Parameters: Project,Camera, Deployment,Image
# This works best going project by project. If an organization is trying to load many projects
# we have code that will dynamically create the four .csv files for as many projects as needed.

# TODO: Update the googlesheets library to googlesheets4 in the R script you are calling this function from. 
library(googlesheets4)
library(dplyr)
library(readr)
gs4_deauth()

save_csv_from_sheet <- function(){
  sheet_map = data.frame(row.names = c(2,3,4,5), val=c("projects", "cameras", "deployments", "images"))
  sheet_id = "1iEcHs0Y49W5hx7aoMSFge_1-Q_VfMdl8d56x27heuNY"
  for(sheet in 2:5){
      batch_type = sheet_map[sheet-1,]
      template = read_sheet(sheet_id, sheet)
      colnames = gsub(" ","_", template$`Column name`)
      df = data.frame(matrix(ncol = length(colnames),nrow = 1))
      colnames(df) <- colnames 
      write_csv(df, paste(batch_type, ".csv", sep=""))
  
      template_req = filter(template, Required == "Yes")
      colnames_req = gsub(" ","_", template_req$`Column name`)
      df = data.frame(matrix(ncol = length(colnames_req),nrow = 1))
      colnames(df) <- colnames_req 
      write_csv(df, paste(batch_type, "_required.csv", sep=""))
  }
}

wi_batch_function <- function(wi_batch_type, df_length){
  csv <- read_csv(paste(wi_batch_type, ".csv", sep=""), show_col_types = FALSE)
  colnames <- colnames(csv)
  df <- data.frame(matrix(ncol = length(colnames),nrow=df_length))
  colnames(df) <- colnames 
  return(df)
}

wi_batch_function_req <- function(wi_batch_type, df_length){
  csv = read_csv(paste(wi_batch_type, "_required.csv", sep=""), show_col_types = FALSE)
  colnames = colnames(csv)
  df = data.frame(matrix(ncol = length(colnames),nrow=df_length))
  colnames(df) <- colnames 
  return(df)
}

# Return Wildlife Insights taxonomies as a data frame. 
wi_get_taxons <- function(){
  wi_taxa <- fromJSON("https://api.wildlifeinsights.org/api/v1/taxonomy/taxonomies-all?fields=class,order,family,genus,species,taxonomyType,iucnCategoryId,uniqueIdentifier,commonNameEnglish&page[size]=30000")
  wi_taxa_data <- wi_taxa$data %>% replace(., is.na(.), "") %>% 
                  rename(wi_taxon_id = uniqueIdentifier, common_name = commonNameEnglish)
  wi_taxa_data = select(wi_taxa_data, class,order,family,genus,species,wi_taxon_id,common_name)
  return(wi_taxa_data)
}

# Join wi_taxon_id column by scientific name
join_taxon_id_by_sci_name <- function(img_df){
  taxons = wi_get_taxons() %>% select(-c("id","taxonomyType"))
  return(left_join(img_df, taxons, by = c("genus", "species")))
}

# Add missing fields to a batch upload template.
add_missing_fields <- function(df, type){
  dictionary <- wi_batch_function(type,1)
  all_equal(dictionary, df, ignore_col_order = TRUE, ignore_row_order = TRUE)
  missed_fields = setdiff(colnames(dictionary), colnames(df))
  
  if(is_empty(missed_fields)){
    print("No missing fields found.")
    return(df)
  }
  else{ 
    print("The following missing fields have been added:")
    print(missed_fields)
    return(cbind(df, 
                 setNames(lapply(missed_fields, function(x) x=NA), 
                 missed_fields)))
  }
}

# Remove additional fields from a batch upload template. 
remove_extra_fields <- function(df, type){
  dictionary <- wi_batch_function(type,1)
  all_equal(dictionary, df, ignore_col_order = TRUE, ignore_row_order = TRUE)
  extra_fields = setdiff(colnames(df), colnames(dictionary))
  if(is_empty(extra_fields)){
    print("No extra fields found.")
    return(df)
    }
  else {
    print("The following fields are extra and have been removed:")
    print(extra_fields)
    return(select(df, -extra_fields))
  } 
}

# Remove additional fields from a batch upload template. 
flag_extra_fields <- function(df, type){
  dictionary <- wi_batch_function(type,1)
  all_equal(dictionary, df, ignore_col_order = TRUE, ignore_row_order = TRUE)
  extra_fields = setdiff(colnames(df), colnames(dictionary))
  if(is_empty(extra_fields)){
    print(paste("No extra fields found in ", type, " template."))
    }
  else {
    print(paste("ERROR: Batch upload template", type ,"has the follwoing extra fields:"))
    print(extra_fields)
  } 
}

# Creates an 'upload' folder in the current working directory.
# and prints batch upload templates as CSVs. 
prep_upload <- function(img_bu, cam_bu, dep_bu, prj_bu){
  folder_name = gsub("^.*/", "", getwd())
  dir.create(folder_name, showWarnings = FALSE)

  write_csv(img_bu,paste(folder_name, "/images.csv", sep=""), na ="")
  write_csv(dep_bu,paste(folder_name, "/deployments.csv", sep=""), na ="")
  write_csv(prj_bu,paste(folder_name, "/projects.csv", sep=""), na ="")
  write_csv(cam_bu,paste(folder_name, "/cameras.csv", sep=""), na ="")
  
  generate_copy_cmd(folder_name)
}

# For large batch uploads (upwards of 1 million images), the batch uploads must
# be split to create smaller uploads. This is done by deployments.  
prep_split_upload <- function(img_bu, cam_bu, dep_bu, prj_bu, parts){

  nr = nrow(dep_bu)
  n = as.integer(ceiling(nr/parts))
  dep_bu_sps = split(dep_bu, rep(1:ceiling(nr/n), each=n, length.out=nr))
  folder = gsub("^.*/", "", getwd())
  i = 1
  for(dep_sp in dep_bu_sps){
    print(i)
    img_bu_split = filter(img_bu, deployment_id %in% dep_sp$deployment_id)
    print(paste("Split size:", nrow(img_bu_split)))
    # Create folders where you splits will be saved.
    # i.e. caltest_1, caltest_2, etc., in this example.
    folder_name = paste(folder, i, sep="_")
    dir.create(folder_name, showWarnings = FALSE)
    write_csv(img_bu_split,paste(folder_name,"/images.csv", sep=""), na ="")
    write_csv(dep_sp,paste(folder_name, "/deployments.csv", sep=""), na ="")
    write_csv(prj_bu,paste(folder_name,"/projects.csv", sep=""), na ="")
    write_csv(cam_bu,paste(folder_name,"/cameras.csv", sep=""), na ="")
    i = i + 1
    
    generate_copy_cmd(folder_name)
  }
}

generate_copy_cmd <- function(folder){
  w_dir = getwd()
  print(paste("gsutil -m cp -R ", w_dir,"/", folder, "/*.csv ", " gs://wildlife_insights_bulk_uploads/", folder, sep=""))
}

# wi_functions.R Eric Fegraus 09-05-2019
# Purpose: Key functions used to help migrate data into the Wilidlife Insights
# Batch Upload formats. 
##############################################################################
# Function: wi_batch_function
# Access the Wildlife Insights Batch Upload templates and return
# empty data frames for Project, Camera, Deployment and Images
# Parameters: Project,Camera, Deployment,Image
# This works best going project by project. If an organization is trying to load many projects
# we have code that will dynamically create the four .csv files for as many projects as needed.

# TODO: Update the googlesheets library to googlesheets4 in the R script you are calling this function from. 
# library(googlesheets4)
# library(dplyr)
# library(readr)
# gs4_deauth()
# 
# wi_batch_function <- function(wi_batch_type, df_length) {
#   sheet_map = data.frame(row.names=c("Project", "Camera", "Deployment", "Image"), val=c(2,3,4,5))
#   sheet = sheet_map[wi_batch_type,]
#   if(!is.na(sheet)){
#     template = read_sheet("1iEcHs0Y49W5hx7aoMSFge_1-Q_VfMdl8d56x27heuNY", sheet)
#     colnames = gsub(" ","_", template$`Column name`)
#     df = data.frame(matrix(ncol = length(colnames),nrow=df_length))
#     colnames(df) <- colnames 
#     return(df)
#   }
#   else{ return("Incorrect function parameter used.")
#   }
# }
# 
# wi_batch_function <- function(wi_batch_type,df_length) {
#   sheet_map = data.frame(row.names=c("Project", "Camera", "Deployment", "Image"), val=c(2,3,4,5))
#   sheet = sheet_map[wi_batch_type,]
#   if(!is.na(sheet)){
#     template <- read_sheet("1iEcHs0Y49W5hx7aoMSFge_1-Q_VfMdl8d56x27heuNY", sheet)
#     colnames <- gsub(" ","_", template$`Column name`)
#     df <- data.frame(matrix(ncol = length(colnames),nrow=df_length))
#     colnames(df) <- colnames 
#     return(df)
#   }
#   else{ return("Incorrect function parameter used")
#   }
# }
# 
# # Returns batch upload templates with all those fields that are required.
# wi_batch_function_req <- function(wi_batch_type, df_length) {
#   sheet_map = data.frame(row.names=c("Project", "Camera", "Deployment", "Image"), val=c(2,3,4,5))
#   sheet = sheet_map[wi_batch_type,]
#   if(!is.na(sheet)){
#     template = read_sheet("1iEcHs0Y49W5hx7aoMSFge_1-Q_VfMdl8d56x27heuNY", sheet)
#     template = filter(template, Required == "Yes")
#     colnames = gsub(" ","_", template$`Column name`)
#     df = data.frame(matrix(ncol = length(colnames),nrow=df_length))
#     colnames(df) <- colnames 
#     return(df)
#   }
#   else{ return("Incorrect function parameter used.")
#   }
# }

# Return Wildlife Insights taxonomies as a data frame. 
# wi_get_taxons <- function(){
#   wi_taxa <- fromJSON("https://api.wildlifeinsights.org/api/v1/taxonomy/taxonomies-all?fields=class,order,family,genus,species,taxonomyType,iucnCategoryId,uniqueIdentifier,commonNameEnglish&page[size]=30000")
#   wi_taxa_data <- wi_taxa$data %>% replace(., is.na(.), "") %>% 
#                   rename(wi_taxon_id = uniqueIdentifier)
#   wi_taxa_data = select(wi_taxa_data, class,order,family,genus,species,wi_taxon_id,commonNameEnglish)
#   return(wi_taxa_data)
# }
# 
# # Join wi_taxon_id column by scientific name
# join_taxon_id_by_sci_name <- function(img_df){
#   taxons = wi_get_taxons() %>% select(-c("id","taxonomyType"))
#   return(left_join(img_df, taxons, by = c("genus", "species")))
# }
# 
# # Add missing fields to a batch upload template.
# add_missing_fields <- function(df, type){
#   dictionary <- wi_batch_function(type,1)
#   all_equal(dictionary, df, ignore_col_order = TRUE, ignore_row_order = TRUE)
#   missed_fields = setdiff(colnames(dictionary), colnames(df))
#   
#   if(is_empty(missed_fields)){
#     print("No missing fields found.")
#     return(df)
#   }
#   else{ 
#     print("The following missing fields have been added:")
#     print(missed_fields)
#     return(cbind(df, 
#                  setNames(lapply(missed_fields, function(x) x=NA), 
#                  missed_fields)))
#   }
# }
# 
# # Remove additional fields from a batch upload template. 
# remove_extra_fields <- function(df, type){
#   dictionary <- wi_batch_function(type,1)
#   all_equal(dictionary, df, ignore_col_order = TRUE, ignore_row_order = TRUE)
#   extra_fields = setdiff(colnames(df), colnames(dictionary))
#   if(is_empty(extra_fields)){
#     print("No extra fields found.")
#     return(df)
#     }
#   else {
#     print("The following fields are extra and have been removed:")
#     print(extra_fields)
#     return(select(df, -extra_fields))
#   } 
# }
# 
# # Remove additional fields from a batch upload template. 
# flag_extra_fields <- function(df, type){
#   dictionary <- wi_batch_function(type,1)
#   all_equal(dictionary, df, ignore_col_order = TRUE, ignore_row_order = TRUE)
#   extra_fields = setdiff(colnames(df), colnames(dictionary))
#   if(is_empty(extra_fields)){
#     print("No extra fields found.")
#     }
#   else {
#     print("ERROR: Batch upload template has extra fields.")
#     print(extra_fields)
#   } 
# }
# 
# # Creates an 'upload' folder in the current working directory.
# # and prints batch upload templates as CSVs. 
# prep_upload <- function(img_bu, cam_bu, dep_bu, prj_bu){
#   folder_name = "upload"
#   dir.create(folder_name, showWarnings = FALSE)
# 
#   write_csv(img_bu,paste(folder_name, "/images.csv", sep=""), na ="")
#   write_csv(dep_bu,paste(folder_name, "/deployments.csv", sep=""), na ="")
#   write_csv(prj_bu,paste(folder_name, "/projects.csv", sep=""), na ="")
#   write_csv(cam_bu,paste(folder_name, "/cameras.csv", sep=""), na ="")
# }
# 
# # For large batch uploads (upwards of 1 million images), the batch uploads must
# # be split to create smaller uploads. This is done by deployments.  
# prep_split_upload <- function(img_bu, cam_bu, dep_bu, prj_bu, parts, folder){
# 
#   nr = nrow(dep_bu)
#   n = as.integer(ceiling(nr/parts))
#   dep_bu_sps = split(dep_bu, rep(1:ceiling(nr/n), each=n, length.out=nr))
#   
#   i = 1
#   for(dep_sp in dep_bu_sps){
#     print(i)
#     img_bu_split = filter(img_bu, deployment_id %in% dep_sp$deployment_id)
#     print(paste("Split size:", nrow(img_bu_split)))
#     # Create folders where you splits will be saved.
#     # i.e. caltest_1, caltest_2, etc., in this example.
#     folder_name = paste(folder, i, sep="_")
#     dir.create(folder_name, showWarnings = FALSE)
#     write_csv(img_bu_split,paste(folder_name,"/images.csv", sep=""), na ="")
#     write_csv(dep_sp,paste(folder_name, "/deployments.csv", sep=""), na ="")
#     write_csv(prj_bu,paste(folder_name,"/projects.csv", sep=""), na ="")
#     write_csv(cam_bu,paste(folder_name,"/cameras.csv", sep=""), na ="")
#     i = i + 1
#   }
# }
