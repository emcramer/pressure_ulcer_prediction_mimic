# for extracting SQL gz data files into R data frames

extractData <- function(filename){
  extracteddata <- readr::read_delim(gzfile(filename), "|", escape_double = FALSE, trim_ws = TRUE)
  extracteddata <- extracteddata[-c(1, nrow(extracteddata)),] # removing the SQL formatted line
  return(extracteddata)
}
