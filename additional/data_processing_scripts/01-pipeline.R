
# 0 Set up pipeline dependencies
source("data-processing/extract-gz.R")
library(dplyr)
library(readr)
library(lubridate)

# 0.0 Read in Masterfile admissions data
cases <- read_csv("data-extraction/data/data_may17/cases_filtered.csv")
controls <- read_csv("data-extraction/data/data_may17/controls_filtered.csv")
colnames(cases) <- tolower(colnames(cases))
cases$intime <- dmy_hm(cases$intime)
colnames(controls) <- tolower(colnames(controls))
controls$intime <- dmy_hm(controls$intime)

# 1 Read in the data file

filename <- "data-extraction/data/data_may17/albuminchartevents.gz"

charteventData <- extractData(filename)
charteventData$charteventscharttime <- ifelse(year(charteventData$charteventscharttime) > 2018, 
                                              charteventData$charteventscharttime - years(100), 
                                              charteventData$charteventscharttime)

# 1.1 Select only the pertinent columns
charteventColumns <- c("icustay_id", "charteventscharttime", "charteventsvalue")
charteventDataSmall <- select(charteventData, charteventColumns)

casesColumns <- c("subject_id", "hadm_id", "icustay_id", "intime")
casesSmall <- select(cases, casesColumns)

controlsColumns <- c("subject_id", "hadm_id", "icustay_id", "intime")
controlsSmall <- select(controls, controlsColumns)

# Clean up
rm(charteventData, charteventColumns)

# 2 Join the cases to the chartevent data
casesEvent <- left_join(casesSmall, charteventDataSmall, by = "icustay_id")


