# extraction check script
# for extracting data files into R data frames

library(readr)

setwd("C:/Users/Eric/Desktop/Spring 2018/bmi212/data-extraction") # set to your own working directory to work
filename <- "allchartevents.gz" # SET THIS!!!

extractData <- function(filename){
  extracteddata <- read_delim(gzfile(filename), "|", escape_double = FALSE, trim_ws = TRUE)
  extracteddata <- extracteddata[-c(1, nrow(extracteddata)),] # removing the SQL formatted line
  return(extracteddata)
}

myData <- extractData(filename)
View(myData)
