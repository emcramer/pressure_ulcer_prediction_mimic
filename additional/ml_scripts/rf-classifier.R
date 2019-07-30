# Limited to carevue DB

# Fits the following models:
# 1. logistic
# 2. RF
# 3. SVM
# 4. KNN
# 5. GBM

# clean out the R environment
rm(list=ls())

# load libraries
library(tidyverse)
library(readr)
library(caret)
library(party)
library(partykit)

# load data
trainData <- read_csv("masterfile-generation/trainData_preprocessed.csv")
testData <- read_csv("masterfile-generation/testData_preprocessed.csv")

################################################################################

# Removing Braden Scores and deprecated 'blood pressure' measures

trainData <- select(trainData, -blood_pressure)
testData <- select(testData, -blood_pressure)

outcomeName <- "pressure_sore"

# if converting outcome variable to numeric
# 1 = "no-ulcer", 2 = "ulcer"

trainData <- trainData %>% mutate_if(is.character, as.factor)
testdata <- testData %>% mutate_if(is.character, as.factor)

################################################################################

################################################################################

## TRAINING MODELS USING PRE-DEFINED TUNEGRIDS

predictors<-names(trainData)[!names(trainData) %in% outcomeName]

# caret package tunegrids
fitControl <- trainControl(
  method = 'cv',                   # k-fold cross validation
  number = 5,                      # number of folds
  savePredictions = 'final',       # saves predictions for optimal tuning parameter
  classProbs = T,                  # should class probabilities be returned
  summaryFunction=twoClassSummary  # results summary function
) 


# simple class weights
model_weights <- ifelse(trainData[[outcomeName]] == "no_ulcer", 
                        1/table(trainData[[outcomeName]])[1] * 0.5, 
                        1/table(trainData[[outcomeName]])[2] * 0.5)

## Predictions with Random Forest
model_rf_weights<-train(trainData[,predictors],trainData[[outcomeName]],
                        method='rf',tuneLength = 5, metric='kappa', trControl = fitControl, 
                        weights = model_weights)


################################################################################

## Predicting with thhe classifier
preds_rf_weights <- predict(model_rf_weights, testData[,predictors])
confusionMatrix(reference=as.numeric(testData[[outcomeName]]), 
                data = as.numeric(preds_rf_weights), mode = 'everything', positive = '2')

################################################################################

## SAVING EVERYTHING TO .RData file
filename <- paste0("no-braden-output-", Sys.Date(), collapse="", sep="")
save.image(file = filename)
