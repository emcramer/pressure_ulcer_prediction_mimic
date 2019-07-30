# load libraries
library(tidyverse)
library(readr)
library(neuralnet)
masterData <- read_csv("masterfile-generation/masterfile_ml_preprocessed.zip")

# convert the character vectors to factors in the data frame

foo <- function(x){
  if(is.character(x)){
    return(as.numeric(as.factor(x)))
  }
}

masterData2 <- apply(masterData, 2, foo)  
masterData3 <- data.matrix(masterData2)

colnames(masterData3)[!is.na(as.numeric(colnames(masterData3)))] <- paste0("X", colnames(masterData3)[!is.na(as.numeric(colnames(masterData3)))])

# separate training and testing sets
sampleSize <- 0.75 * nrow(masterData3)
set.seed(2018)
idx <- sample(nrow(masterData3), size = sampleSize)

train <- masterData3[idx, ]
test <- masterData3[-idx, ]

# scale the data for a neural network
maxVal <- apply(masterData3, 2, max)
minVal <- apply(masterData3, 2, min)
scaledData <- as.data.frame(scale(masterData3, center = minVal, scale = maxVal - minVal))

# setting NAs to -99
scaledData[is.na(scaledData)] <- -99

# set up train/test sets
trainNN <- scaledData[idx, -1]
testNN <- scaledData[-idx, -1]

# create formula
# f <- reformulate(setdiff(colnames(trainNN), "X_pressure_sore"), response="X_pressure_sore")
f <- reformulate(setdiff(colnames(trainNN), "pressure_sore"), response="pressure_sore")
                
# fit the neural network
set.seed(2018)
NN <- neuralnet(f, data = trainNN, hidden = 1 , linear.output = T )

# plot neural network
# plot(NN, main = "PU Predicting Neural Network") # <-- will cause a crash

# evaluate the NN
predict_testNN <- compute(NN, testNN)
predict_testNN <- (predict_testNN$net.result * (max() - min(data$rating))) + min(data$rating)
