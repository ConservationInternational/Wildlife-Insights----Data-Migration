# Wildlife-Insights----Data-Migration
This GitHub repository contains code that will assist current and future Wildlife Insights data providers to get their data into the format required to be uploaded into Wildlife Insights. The [Wildlife Insights Batch Upload Template Data Dictionaries](https://docs.google.com/spreadsheets/d/1PE5Zl-HUG4Zt0PwSfj-gJRJVbZ__LgH3VuiDW3-BKQg/edit#gid=807650760) contain the guidelines for creating these templates. All code examples in this repository end up producing these templates.

Our goal is to have data migration code for all the software programs and standards mentioned in the [Young et al paper](https://github.com/ConservationInternational/Wildlife-Insights----Data-Migration/blob/master/Young%20et%20al%202018%20CT%20data%20mgmt%20review.pdf).  If your data is in another format contact us and let us know how we can help. 

### GitHub Repository Description
```Datasets``` A place to store your dataset that neeeds to be transformed. This also contains an example dataset.

```Docs``` Miscellaneous documents and papers related to data migration and standard formats.

```Transformation_Code``` Code (usually in R or Python) that has been used to migrate datasets from some format into the _Wildlife Insights Batch Upload_ templates. All code is a in directory with the name of the: source software, program, format or organization that owned the datasets. The goal is to 1) identify the orginal format or source so that it will be useful to anyone starting from these formats and 2) archive this code so that is can be the basis for new code needed for new data formats. 

```WI_Global_Taxonomy``` This directory contains tools that will help you map your taxonomy (the scientific taxonomy or common names you use in your dataset) to our Wildlife Insights Global Taxonomy.

# Getting Started 
1. If you are going to use R, python or another language and want to use the code available here, modify it or use it as psuedo-code for what you want to write all you need to do is clone or download this repository. Do this by selecting the options in the  _top right of this page_. 
2. Create a taxonomic mapping between your taxonomic data and the Wildlife Inisghts Global Taxonomy (WIGT). The WI_Global_Taxonomy directory contains tools to help you build a look up table that maps the names (i.e. the taxonomic or common names to describe wildlife and objects seen in your images) to our WIGT. We will be building this out more to add in additional tools to help identify scientific name issues, better handle situations where identification was done using common names and ultimately help you make a mapping between your data and the WI Global Taxonomy.
3. Utilize one of the R scripts from the Dataset_Transformations or the Example_Transformation directory  above as an example to transform your data into the Batch Upload Templates recognized by the Wildlife Insights Platform. If you need help with this please email info@wildlifeinsights.org describing your projects.
4. Upload your images into the Google Cloud Platform. Please create a [Google Cloud Account](https://console.cloud.google.com) and then contact info@wildlifeinsights.org for specific instructions on how to upload your images.


# Getting R Setup Locally
If you want to use R and haven't done this before initial instructions for installing R, RStudio and Git (if desired) are below.
1. Install R: You can download the latest version of R [here](https://cran.rstudio.com).
2. Install Rstudio: [Rstudio Download link](https://www.rstudio.com/products/rstudio/download/)
3. Install Git: [See these installation notes](https://support.rstudio.com/hc/en-us/articles/200532077-Version-Control-with-Git-and-SVN) _only needed if you want to share your code with this repository).
4. Clone or download this directory

# Contact Us
If you have any questions or need help getting your data into the _WI Batch Upload Templates_  please contact us at <info@wildlifeinsights.org>.
