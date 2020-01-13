# Wildlife-Insights----Data-Migration
This repo contains code that will assist current or future Wildlife Insights data providers to get their data into the format required to be uploaded into Wildlife Insights. 

Upload Format - [Batch Upload Template Data Dictionaries](https://docs.google.com/spreadsheets/d/1PE5Zl-HUG4Zt0PwSfj-gJRJVbZ__LgH3VuiDW3-BKQg/edit#gid=807650760)

Our goal is to have software migration to function with all the software programs mentioned in the [Young et al paper](https://github.com/ConservationInternational/Wildlife-Insights----Data-Migration/blob/master/Young%20et%20al%202018%20CT%20data%20mgmt%20review.pdf)

A directory with the Source Name will be created for each camera trap data source. Custom scripts for non-standardized data sources should be included in the Custom Sources Directory

# Setting Up Your Environment
1. Install R: You can download the latest version of R [here](https://cran.rstudio.com).
2. Install Rstudio: [Rstudio Download link](https://www.rstudio.com/products/rstudio/download/)
3. Install Git: [See these installation notes](https://support.rstudio.com/hc/en-us/articles/200532077-Version-Control-with-Git-and-SVN)
4. Clone or download this directory

# Getting Started
1. Create a taxonomic mapping between your taxonomic data and the Wildlife Inisghts Global Taxonomy (WIGT). The WI_Global_Taxonomy directory contains tools to help you build a look up table that maps the names (i.e. the taxonomic or common names to describe wildlife and objects seen in your images) to our WIGT. We will be building this out more to add in additional tools to help identify scientific name issues, better handle situations where identification was done using common names and ultimately help you make a mapping between your data and the WI Global Taxonomy.
2. Utilize one of the R scripts from the Dataset_Transformations or the Example_Transformation directory  above as an example to transform your data into the Batch Upload Templates recognized by the Wildlife Insights Platform. If you need help with this please email info@wildlifeinsights.org describing your projects.
3. Upload your images into the Google Cloud Platform. Please create a [Google Cloud Account](https://console.cloud.google.com) and then contact info@wildlifeinsights.org for specific instructions on how to upload your images.

