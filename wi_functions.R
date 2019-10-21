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
#

wi_batch_function <- function(wi_batch_type,df_length) {
  wi_batch<- gs_url("https://docs.google.com/spreadsheets/d/1PE5Zl-HUG4Zt0PwSfj-gJRJVbZ__LgH3VuiDW3-BKQg", visibility = "public")
  if (wi_batch_type == "Project") {
    project_batch <- wi_batch %>% gs_read_csv(ws="Projectv1.0")
    prj_df_colnames <- project_batch$`Validator Name`
    prj_df_colnames <- gsub(" ","_",prj_df_colnames)
    prj_df_length <- df_length
    prj_dff <- data.frame(matrix(ncol = length(prj_df_colnames),nrow=df_length))
    colnames(prj_dff) <- prj_df_colnames 
    return(prj_dff) # Return prj_dff as data frame
  } else if (wi_batch_type == "Camera") {
    
    # #Camerav1.0
    cam_batch <- wi_batch %>% gs_read_csv(ws="Camerav1.0")
    cam_df_colnames <- cam_batch$`Validator Name`
    cam_df_colnames <- gsub(" ","_",cam_df_colnames)
    # Make cam_df_length unique to the number of cameras in the project
    cam_df_length <- df_length # or use nrow
    cam_dff <- data.frame(matrix(ncol = length(cam_df_colnames),nrow=cam_df_length))
    colnames(cam_dff) <- cam_df_colnames
    return(cam_dff) # Return prj_dff as data frame
    
  } else if (wi_batch_type == "Deployment") {
    #Deploymentv1.0
    dep_batch <- wi_batch %>% gs_read_csv(ws="Deploymentv1.0")
    dep_df_colnames <- dep_batch$`Validator Name`
    dep_df_colnames <- gsub(" ","_",dep_df_colnames)
    # Make dep_df_length unique to the number of cameras in the project
    #dep_df_length <- length(unique(paste(ct_data$Site.Name,ct_data$Session.Start.Date,ct_data$Session.End.Date,sep="-")))
    # Custom to TEAM
    dep_df_length <- df_length
    dep_dff <- data.frame(matrix(ncol = length(dep_df_colnames),nrow=dep_df_length))
    colnames(dep_dff) <- dep_df_colnames
    return(dep_dff) # Return prj_dff as data frame
    
  } else if (wi_batch_type == "Image") {
    #Imagev1.0
    image_batch <- wi_batch %>% gs_read_csv(ws="Imagev1.0")
    image_df_colnames <- image_batch$`Validator Name`
    image_df_colnames <- gsub(" ","_",image_df_colnames)
    # Set number of rows to full dataset.
    image_df_length <- df_length
    #image_df_length <- nrow(ct_data)
    image_dff <- data.frame(matrix(ncol = length(image_df_colnames),nrow=image_df_length))
    colnames(image_dff) <- image_df_colnames   
    return(image_dff) # Return prj_dff as data frame
    
  } else {
    error_text <- c("Incorrect function parameter used")   
    return(error_text)
  }
}
