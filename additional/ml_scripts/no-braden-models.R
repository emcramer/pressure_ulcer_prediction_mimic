# Running models without Braden score
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

braden_features <- c('BRADEN_SCORE', 'ACTIVITY_SCORE', 'MOISTURE_SCORE', 'MOBILITY_SCORE', 
                     'SENSORY_SCORE', 'NUTRITION_SCORE', 'SHEAR_SCORE')
trainData <- select(trainData, -blood_pressure)
testData <- select(testData, -blood_pressure)
# trainData <- select(trainData, -one_of(braden_features))
# testData <- select(testData, -one_of(braden_features))

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

# By setting the classProbs=T the probability scores are generated instead of directly predicting the class based on a predetermined cutoff of 0.5.  Important for CALIBRATION. 

factorNumeric <- function(x){
  y <- x %>% mutate_if(is.factor, as.numeric)
  return(y)
}

# GLM
model_glm<-train(trainData[,predictors],trainData[[outcomeName]],
                 method='glm', family='binomial', tuneLength = 5, metric='ROC', trControl = fitControl)

# RF
model_rf<-train(trainData[,predictors],trainData[[outcomeName]],
                method='rf',tuneLength = 5, metric='ROC', trControl = fitControl)

# MARS
model_mars = train(factorNumeric(trainData[,predictors]),as.numeric(trainData[[outcomeName]]), 
                   method='earth', tuneLength = 5, metric='ROC', trControl = fitControl)

# Linear Kernel SVM
model_svmLin = train(factorNumeric(trainData[,predictors]),as.numeric(trainData[[outcomeName]]), 
                     method='svmLinear', tuneLength = 5, metric='ROC', trControl = fitControl)

# Poly Kernel SVM
model_svmPoly = train(factorNumeric(trainData[,predictors]),as.numeric(trainData[[outcomeName]]), 
                      method='svmPoly', tuneLength = 5, metric='ROC', trControl = fitControl)

# Gradient Boosted Machine
model_gbm_roc <- train(trainData[,predictors],trainData[[outcomeName]],
                 method='gbm', tuneLength = 5, metric='ROC', trControl = fitControl)
model_gbm_kappa <- train(trainData[,predictors], trainData[[outcomeName]],
                         method = 'gbm', tuneLength = 5, metric = 'kappa', trControl = fitControl)

# XGB
model_xgb <- train(trainData[,predictors],trainData[[outcomeName]],
                   method='xgbTree', tuneLength = 5, metric='ROC', trControl = fitControl)

# Neural Network
model_nnet<-train(trainData[,predictors],trainData[[outcomeName]],
                  method='nnet',tuneLength = 5, metric='ROC', trControl = fitControl)

# party/cpart tunegrids
# control <- ctree_control(testtype = c("Bonferroni", "MonteCarlo", "Univariate", "Teststatistic"),
#                          pargs = GenzBretz(),alpha = 0.05,
#                          minbucket = 7L,
#                          stump = FALSE, lookahead = FALSE, MIA = FALSE, nresample = 9999L,
#                          mtry = 20, maxdepth = 20)
# 
# # Decision Tree
# model_ctree = ctree(pressure_sore ~ real_age + ACTIVITY_SCORE +BRADEN_SCORE + factor(ulcer_free_admission.1), 
#                     data = trainData, control = control)
# 
# # Forest
# model_cforest = cforest(pressure_sore ~ ., data = trainData)

################################################################################

## COMPARING MULTIPLE MODEL PERFORMANCE ON TRAINING SET. 

models_compare <- resamples(list(GBMROC = model_gbm_roc, GBMKAPPA = model_gbm_kappa))

#models_compare <- resamples(list(RF=model_rf, LR = model_glm, GBMROC = model_gbm_roc, GBMKAPPA = model_gbm_kappa,
                      #           MARS=model_mars, LinSVM=model_svmLin, PolySVM = model_svmPoly))

# Summary of the models performances
summary(models_compare)

# Draw box plots to compare models
scales <- list(x=list(relation="free"), y=list(relation="free"))
bwplot(models_compare, scales=scales)

################################################################################

# selecting the GBM model and optimizing for 'kappa', not ROC
fitControl$seeds <- model_gbm_kappa$control$seeds

# simple class weights
model_weights <- ifelse(trainData[[outcomeName]] == "no_ulcer", 
                        1/table(trainData[[outcomeName]])[1] * 0.5, 
                        1/table(trainData[[outcomeName]])[2] * 0.5)
model_gbm_weights <- train(trainData[,predictors], trainData[[outcomeName]],
                         method = 'gbm', tuneLength = 5, metric = 'kappa', trControl = fitControl)

# upsampling the cases
upWeightCntrl <- fitControl
upWeightCntrl$sampling <- "up"
model_gbm_up <- train(trainData[,predictors], trainData[[outcomeName]],
                         method = 'gbm', tuneLength = 5, metric = 'kappa', trControl = upWeightControl)

# downsampling the controls
dwnWeightCntrl <- fitControl
dwnWeightCntrl$sampling <- "down"
model_gbm_dwn <- train(trainData[,predictors], trainData[[outcomeName]],
                         method = 'gbm', tuneLength = 5, metric = 'kappa', trControl = dwnWeightControl)

# using smote class balancing
smoteWeightCntrl <- fitControl
smoteWeightCntrl$sampling <- "smote"
model_gbm_smote <- train(trainData[,predictors], trainData[[outcomeName]],
                         method = 'gbm', tuneLength = 5, metric = 'kappa', trControl = smoteControl)

################################################################################

## COMPARING DIFFERENT SAMPLED GBM MODEL PERFORMANCES ON TRAINING SET

sampled_models_compare <- resamples(list(GBMUP = model_gbm_up, GBMDWN = model_gbm_dwn, GBMWEIGHTS = model_gbm_weights,
                                 GBMSMOTE = model_gbm_smote))

#models_compare <- resamples(list(RF=model_rf, LR = model_glm, GBMROC = model_gbm_roc, GBMKAPPA = model_gbm_kappa,
#           MARS=model_mars, LinSVM=model_svmLin, PolySVM = model_svmPoly))

# Summary of the models performances
summary(sampled_models_compare)

# Draw box plots to compare models
scales <- list(x=list(relation="free"), y=list(relation="free"))
bwplot(sampled_models_compare, scales=scales)

################################################################################

## Checking performance of GBMs on the test set

# predict values from test set
preds_gbm_kappa <- predict(model_gbm_kappa, testData[, predictors])
preds_gbm_weights <- predict(model_gbm_weights, testData[,predictors])
preds_gbm_up <- predict(model_gbm_up, testData[,predictors])
preds_gbm_dwn <- predict(model_gbm_dwn, testData[,predictors])
preds_gbm_smote <- predict(model_gbm_smote, testData[,predictors])

# calculate confusion matrix
gbm_kappa_cm <- confusionMatrix(reference=as.numeric(testData[[outcomeName]]), 
                data = as.numeric(preds_gbm_kappa), mode = 'everything', positive = '2')
gbm_weights_cm <- confusionMatrix(reference=as.numeric(testData[[outcomeName]]), 
                                data = as.numeric(preds_gbm_weights), mode = 'everything', positive = '2')
gbm_up_cm <- confusionMatrix(reference=as.numeric(testData[[outcomeName]]), 
                                data = as.numeric(preds_gbm_up), mode = 'everything', positive = '2')
gbm_dwn_cm <- confusionMatrix(reference=as.numeric(testData[[outcomeName]]), 
                                data = as.numeric(preds_gbm_dwn), mode = 'everything', positive = '2')
gbm_smote_cm <- confusionMatrix(reference=as.numeric(testData[[outcomeName]]), 
                                data = as.numeric(preds_gbm_smote), mode = 'everything', positive = '2')

################################################################################

## Predictions with Random Forest
# RF
model_rf_weights<-train(trainData[,predictors],trainData[[outcomeName]],
                method='rf',tuneLength = 5, metric='kappa', trControl = fitControl, weights = model_weights)

################################################################################

## SAVING EVERYTHING TO .RData file
filename <- paste0("no-braden-output-", Sys.Date(), collapse="", sep="")
save.image(file = filename)
