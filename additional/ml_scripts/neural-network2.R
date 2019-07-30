# load libraries
library(tidyverse)
library(readr)
library(neuralnet)
masterData <- read_csv("masterfile-generation/masterfile_ml_preprocessed.zip")

# separate training and testing sets
sampleSize <- 0.75 * nrow(masterData)
set.seed(2018)
idx <- sample(nrow(masterData), size = sampleSize)

train <- masterData[idx, ]
test <- masterData[-idx, ]

# scale the data for a neural network
maxVal <- apply(masterData, 2, max)
minVal <- apply(masterData, 2, min)
scaledData <- as.data.frame(scale(masterData, center = minVal, scale = maxVal - minVal))

# set up train/test sets
trainNN <- scaledData[idx, -1]
testNN <- scaledData[-idx, -1]

# create formula
f <- reformulate(setdiff(colnames(trainNN), "pressure_sore"), response="pressure_sore")

# fit the neural network
set.seed(2018)
NN <- neuralnet(f, data = trainNN, hidden = 1 , linear.output = T )

