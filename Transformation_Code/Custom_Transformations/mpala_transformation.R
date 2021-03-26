rm(list=ls())
# Load Libraries
library(dplyr)
library(readxl)
library(openxlsx)
library(googlesheets)
library(jsonlite)
library(stringr)
library(lubridate)


#Import CSVs
dep <- read.csv("/Users/anthonyngo/Documents/Wildlife_Insights/MpalaForestGeo/deployments.csv")
img <- read.csv("/Users/anthonyngo/Documents/Wildlife_Insights/MpalaForestGeo/images.csv")
prj <- read.csv("/Users/anthonyngo/Documents/Wildlife_Insights/MpalaForestGeo/projects.csv")

# Deployment Start Date
start_dates <- str_split(dep$start_date, "/")
start_m <- str_pad(lapply(start_dates, `[[`, 1), 2, pad="0")
start_d <- str_pad(lapply(start_dates, `[[`, 2), 2, pad="0")
start_y <- paste(20, lapply(start_dates, `[[`, 3), sep="")

formatted_start_date <- paste(start_y, start_m, start_d, sep="-")
dep$start_date <- paste(formatted_start_date, "00:00:00", sep=" ")

rm(start_dates, start_m, start_d, start_y, formatted_start_date)

# Deployment End Date
end_dates <- str_split(dep$end_date, "/")
end_m <- str_pad(lapply(end_dates, `[[`, 1), 2, pad="0")
end_d <- str_pad(lapply(end_dates, `[[`, 2), 2, pad="0")
end_y <- paste(20, lapply(end_dates, `[[`, 3), sep="")

formatted_end_date <- paste(end_y, end_m, end_d, sep="-")
dep$end_date <- paste(formatted_end_date, "00:00:00", sep=" ")

rm(end_dates, end_m, end_d, end_y, formatted_end_date)

# Image Timestamps
ts <- str_split(img$timestamp, " ")
ts_dates <- str_split(lapply(ts, `[[`, 1), "/")
ts_m <- str_pad(lapply(ts_dates, `[[`, 1), 2, pad="0")
ts_d <- str_pad(lapply(ts_dates, `[[`, 2), 2, pad="0")
ts_y <- paste(20, lapply(ts_dates, `[[`, 3), sep="")

formatted_ts_date <- paste(ts_y, ts_m, ts_d, sep="-")

ts_time <- str_split(lapply(ts, `[[`, 2), ":")
ts_hour <- str_pad(lapply(ts_dates, `[[`, 1), 2, pad="0")
ts_min <- str_pad(lapply(ts_dates, `[[`, 2), 2, pad="0")
ts_formatted_time <- paste(ts_hour, ts_min, "00", sep=":")

img$timestamp <- paste(formatted_ts_date, ts_formatted_time, sep=" ")

img$age <- ""
img$animal_recognizable <- ""
img$sex <- ""

# Project Fixes
prj$embargo <- 24
prj$project_bait_type <-  "None"
prj$project_sensor_method <- "Sensor Detection"
prj$initiative_id <- 1

# Outputting edited files
write.table(dep,file="/Users/anthonyngo/Documents/Wildlife_Insights/MpalaForestGeo/output/deployments.csv", row.names = FALSE, sep=",")
write.table(img,file="/Users/anthonyngo/Documents/Wildlife_Insights/MpalaForestGeo/output/images.csv", row.names = FALSE, sep=",")
write.table(prj,file="/Users/anthonyngo/Documents/Wildlife_Insights/MpalaForestGeo/output/projects.csv", row.names = FALSE, sep=",")




