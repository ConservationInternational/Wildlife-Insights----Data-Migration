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
    colnames <- gsub(" ","_", template$`Validator Name`)
    df <- data.frame(matrix(ncol = length(colnames),nrow=df_length))
    colnames(df) <- colnames 
    return(df)
  }
  else{ return("Incorrect function parameter used")
  }
}
