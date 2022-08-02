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
gs4_deauth()

wi_batch_function <- function(wi_batch_type,df_length) {
  sheet_map = data.frame(row.names=c("Project", "Camera", "Deployment", "Image"), val=c(2,3,4,5))
  sheet = sheet_map[wi_batch_type,]
  if(!is.na(sheet)){
    template <- read_sheet("1iEcHs0Y49W5hx7aoMSFge_1-Q_VfMdl8d56x27heuNY", sheet)
    colnames <- gsub(" ","_", template$`Column name`)
    df <- data.frame(matrix(ncol = length(colnames),nrow=df_length))
    colnames(df) <- colnames 
    return(df)
  }
  else{ return("Incorrect function parameter used")
  }
}

# Returns batch upload templates with all those fields that are required.
wi_batch_function_req <- function(wi_batch_type, df_length) {
  sheet_map = data.frame(row.names=c("Project", "Camera", "Deployment", "Image"), val=c(2,3,4,5))
  sheet = sheet_map[wi_batch_type,]
  if(!is.na(sheet)){
    template = read_sheet("1iEcHs0Y49W5hx7aoMSFge_1-Q_VfMdl8d56x27heuNY", sheet)
    template = filter(template, Required == "Yes")
    colnames = gsub(" ","_", template$`Column name`)
    df = data.frame(matrix(ncol = length(colnames),nrow=df_length))
    colnames(df) <- colnames 
    return(df)
  }
  else{ return("Incorrect function parameter used.")
  }
}

# Return Wildlife Insights taxonomies as a data frame. 
wi_get_taxons <- function(){
  wi_taxa <- fromJSON("https://api.wildlifeinsights.org/api/v1/taxonomy?fields=class,order,family,genus,species,taxonomyType,iucnCategoryId,uniqueIdentifier,commonNameEnglish&page[size]=30000")
  wi_taxa_data <- wi_taxa$data %>% replace(., is.na(.), "") %>% 
                  rename(wi_taxon_id = uniqueIdentifier)
  wi_taxa_data = select(wi_taxa_data, class,order,family,genus,species,wi_taxon_id,commonNameEnglish)
  return(wi_taxa_data)
}

# Join wi_taxon_id column by scientific name
join_taxon_id_by_sci_name <- function(img_df){
  taxons = wi_get_taxons() %>% select(-c("id","taxonomyType"))
  return(left_join(img_df, taxons, by = c("genus", "species")))
}

# Creates an 'upload' folder in the current working directory.
# and prints batch upload templates as CSVs. 
prep_upload <- function(img_bu, cam_bu, dep_bu, prj_bu){
  folder_name = "upload"
  dir.create(folder_name, showWarnings = FALSE)

  write_csv(img_bu,paste(folder_name, "/images.csv", sep=""), na ="")
  write_csv(dep_bu,paste(folder_name, "/deployments.csv", sep=""), na ="")
  write_csv(prj_bu,paste(folder_name, "/projects.csv", sep=""), na ="")
  write_csv(cam_bu,paste(folder_name, "/cameras.csv", sep=""), na ="")
}
