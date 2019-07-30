library(dplyr)
library(readr)

Sys.setenv(TZ='UTC')

braden <- read_csv('braden_scores_cleaned.csv')

uber_matrix <- read_delim("Downloads/uber_matrix.tsf", 
                          "\t", escape_double = FALSE, trim_ws = TRUE)

cases_controls <- read_csv("cases_controls_master_stage_2.csv", 
                           col_types = cols(DOB = col_skip(), DOD = col_skip(), 
                                            INTIME = col_datetime(format = "%Y-%m-%d %H:%M:%S"), 
                                            OUTTIME = col_datetime(format = "%Y-%m-%d %H:%M:%S"), 
                                            ROW_ID = col_skip(), X1 = col_skip(), 
                                            admittime = col_datetime(format = "%Y-%m-%d %H:%M:%S")))

cases_controls <- select(cases_controls, -first_recorded_1)
master_vitals <- read_csv("Downloads/master_vitals.csv", 
                          col_types = cols(X1 = col_skip()))

icd9_features <- read_csv("OneDrive - Leland Stanford Junior University/Stanford course notes/Spring18/BMI212/BMI212_data/icd9_feature_matrix.csv")

masterfile <- cases_controls %>% select(-LAST_CAREUNIT, -FIRST_WARDID) %>% 
  left_join(braden, by='ICUSTAY_ID') %>% 
  left_join(uber_matrix, by=c('ICUSTAY_ID'='icustay_id')) %>% 
  left_join(master_vitals, by="ICUSTAY_ID") %>% 
  left_join(icd9_features, by="ICUSTAY_ID")

write.csv(masterfile,'masterfile.csv')

masterfile %>% distinct(ICUSTAY_ID) %>% nrow()
# 44012 distinct ICU stays

masterfile %>% distinct(HADM_ID) %>% nrow()
# 41494 distinct admissions 

masterfile %>% distinct(SUBJECT_ID) %>% nrow()
# 33041 distinct patients

count(masterfile, pressure_sore)

#############################################################

# STRIP OUT UNECESSARY VARIABLES AND PREP FOR ML 
# CALCULATE TIME_TO_ADMIT (time from admission time to ICU INTIME) 

#ONLY SELECT CAREVUE PATIENTS
masterfile <- filter(masterfile, DBSOURCE=="carevue")
masterfile.ml <- masterfile %>% select(-SUBJECT_ID, -ICUSTAY_ID, -LOS, -survival_days, -twelveMoMortality, -OUTTIME, -max_stage, -record_count, -last_stage, -first_stage,
                                       -diff_stage, -time_to_onset, -insurance, -EXPIRE_FLAG, -X1) %>% 
  mutate(time_to_admit = as.numeric(difftime(INTIME,admittime,units="days"))) %>% select(-admittime,-BNP,-age,-DBSOURCE,-CRP,-INTIME, -ESR, -o2sat, -direct_bilirubin, -indirect_bilirubin, -HbA1c,-HADM_ID,-subject_id,-hadm_id,-first_recorded)

#names(masterfile.ml)
masterfile.ml$stage_1_in_24h[is.na(masterfile.ml$stage_1_in_24h)] <- 0
masterfile.ml$stage_1_in_24h <- as.factor(masterfile.ml$stage_1_in_24h)
masterfile.ml$ventilator <- as.factor(masterfile.ml$ventilator)
masterfile.ml$ulcer_free_admission <- as.factor(masterfile.ml$ulcer_free_admission)
masterfile.ml$FIRST_CAREUNIT <- as.factor(masterfile.ml$FIRST_CAREUNIT)
masterfile.ml$LAST_WARDID <- as.factor(masterfile.ml$LAST_WARDID)
masterfile.ml$GENDER <- as.factor(masterfile.ml$GENDER)
masterfile.ml$confusion <- as.factor(masterfile.ml$confusion)
masterfile.ml$prd <- as.factor(masterfile.ml$prd)
masterfile.ml$pressure_sore <- as.factor(masterfile.ml$pressure_sore)
levels(masterfile.ml$pressure_sore)
levels(masterfile.ml$pressure_sore) <- c("no_ulcer","ulcer") # R variable names cannot be 0/1  

library(stringr)
masterfile.ml <- masterfile.ml %>% mutate(ethnicity=ifelse(str_detect(ethnicity,"ASIAN"),"Asian",ethnicity))
masterfile.ml <- masterfile.ml %>% mutate(ethnicity=ifelse(str_detect(ethnicity,"HISPANIC"),"Hispanic",ethnicity))
masterfile.ml <- masterfile.ml %>% mutate(ethnicity=ifelse(str_detect(ethnicity,"BLACK"),"Black",ethnicity))
masterfile.ml <- masterfile.ml %>% mutate(ethnicity=ifelse(str_detect(ethnicity,"WHITE"),"White",ethnicity))
masterfile.ml <- masterfile.ml %>% mutate(ethnicity=ifelse(str_detect(ethnicity,"SOUTH"),"Hispanic",ethnicity))
masterfile.ml <- masterfile.ml %>% mutate(ethnicity=ifelse(str_detect(ethnicity,"UNABLE"),"UNKNOWN/NOT SPECIFIED",ethnicity))
masterfile.ml <- masterfile.ml %>% mutate(ethnicity=ifelse(str_detect(ethnicity,"DECLINED"),"UNKNOWN/NOT SPECIFIED",ethnicity))
masterfile.ml <- masterfile.ml %>% mutate(ethnicity=ifelse(str_detect(ethnicity,"MULTI"),"OTHER",ethnicity))
masterfile.ml <- masterfile.ml %>% mutate(ethnicity=ifelse(str_detect(ethnicity,"PORTUGUESE"),"White",ethnicity))
masterfile.ml <- masterfile.ml %>% mutate(ethnicity=ifelse(str_detect(ethnicity,"CARIBBEAN"),"Black",ethnicity))
masterfile.ml <- masterfile.ml %>% mutate(ethnicity=ifelse(str_detect(ethnicity,"MIDDLE"),"White",ethnicity))
masterfile.ml <- masterfile.ml %>% mutate(ethnicity=ifelse(str_detect(ethnicity,"NATIVE"),"Other",ethnicity))
masterfile.ml <- masterfile.ml %>% mutate(ethnicity=ifelse(str_detect(ethnicity,"OTHER"),"Other",ethnicity))
masterfile.ml <- masterfile.ml %>% mutate(ethnicity=ifelse(str_detect(ethnicity,"UNKNOWN/NOT SPECIFIED"),"Unknown",ethnicity))

unique(masterfile.ml$ethnicity)
masterfile.ml$ethnicity <- as.factor(masterfile.ml$ethnicity)

write.csv(masterfile.ml, 'masterfile_ml.csv')
#############################################################

#### MISSINGNESS

propmiss <- function(dataframe) lapply(dataframe,function(x) data.frame(nmiss=sum(is.na(x)), n=length(x), propmiss=sum(is.na(x))/length(x)))
propmiss(masterfile.ml)


#############################################################

# REMOVE ROWS WITH > X% MISSING DATE

#masterfile.ml$na_count <- apply(masterfile.ml, 1, function(x) sum(is.na(x)))

#hist(masterfile.ml$na_count)

#X=20
#masterfile.ml <- masterfile.ml %>% filter(na_count <= X) %>% select(-na_count) 

#############################################################

## SUMMARY 

library(skimr)
skimmed <- skim_to_wide(masterfile.ml)
skimmed[1:20, c(1:5, 9:11, 13, 15:16)]

#############################################################

# TRAIN/TEST SPLIT

library(caret)
set.seed(100)

outcomeName <- 'pressure_sore'
icd9_predictors <- colnames(masterfile.ml)[40:193]
other_predictors <- colnames(masterfile.ml)[!colnames(masterfile.ml) %in% c(icd9_predictors,outcomeName)]
masterfile.ml[,icd9_predictors][is.na(masterfile.ml[,icd9_predictors])] <- 0

trainRowNumbers <- createDataPartition(masterfile.ml$pressure_sore, p=0.8, list=FALSE)
trainData <- masterfile.ml[trainRowNumbers,]
testData <- masterfile.ml[-trainRowNumbers,]

#pca1 = prcomp(USArrests, scale. = TRUE)
#colnames(trainData)[c(86,146,191)] <- c("drop1",'drop2','drop3')
#trainData.raw.imputed <- dplyr::select(trainData, -drop1, -drop2, -drop3)
#basicPreprocess <- preProcess(trainData.raw.imputed, method=c('medianImpute','scale','center'))
#basicPreprocess
#trainData.raw.imputed <- predict(basicPreprocess, newdata = trainData.raw.imputed)
#anyNA(trainData.raw.imputed)

#############################################################
x.train.preprocess <- trainData[,other_predictors]
x.train.icd <- trainData[,icd9_predictors]
y.train <- select(trainData,pressure_sore)

x.test.preprocess <- testData[,other_predictors]
x.test.icd <- testData[,icd9_predictors]
y.test <- select(testData,pressure_sore)

#############################################################

### CENTER, SCALE, MEAN IMPUTATON OF CONTINUOUS VARIABLES (consider also KNN IMPUTATION)
# https://www.machinelearningplus.com/machine-learning/caret-package/
# https://machinelearningmastery.com/pre-process-your-dataset-in-r/

#preProcess_missingdata_model <- preProcess(x.train, method='knnImpute')

preProcess_missingdata_model <- preProcess(x.train.preprocess, method=c('medianImpute','scale','center'))
preProcess_missingdata_model
dmy <- dummyVars("~ .", data = x.train.preprocess, fullRank = TRUE)
dmy

#library(RANN)  # required for knnImpute. KnnImpute considred but too much missingness. 
x.train.preprocess <- predict(preProcess_missingdata_model, newdata = x.train.preprocess)
x.train.preprocess <- data.frame(predict(dmy, newdata = x.train.preprocess))

## Check if any more missing data. 
anyNA(x.train.preprocess)

# str(x.train)

#############################################################

## COMINE AGAIN WITH ICD9 PREDICTORS WHICH DID NOT REQUIRE PREPROCESSING

trainData<-cbind(x.train.preprocess,x.train.icd, y.train)
anyNA(trainData)

write.csv(trainData,'masterfile_ml_preprocessed.csv')
#############################################################

## FEATURE DISTIBUTION 

#x.train$outcome <- y.train$pressure_sore
#dim(x.train)

#featurePlot(x=x.train$blood_glucose, y=x.train$outcome, "pairs")

#featurePlot(x = x.train[, 30:32], y = x.train$outcome,plot = "pairs",strip=strip.custom(par.strip.text=list(cex=.7)),scales = list(x = list(relation="free"), y = list(relation="free")))

#############################################################

## RECURSIVE FEATURE ELIMINATION
outcomeName<-'pressure_sore' 
predictors<-names(x.train)[!names(x.train) %in% outcomeName]

subsets <- c(5, 10, 15, 20,30,40,50,55)

ctrl <- rfeControl(functions = rfFuncs,
                   method = "repeatedcv",
                   repeats = 5,
                   verbose = FALSE)

lmProfile <- rfe(x=x.train[, 1:55], y=x.train$outcome,
                 sizes = subsets,
                 rfeControl = ctrl)

lmProfile

############################################################

## TRAINING MODELS USING PRE-DEFINED TUNEGRIDS
#x.train$outcome <- y.train$pressure_sore

predictors<-names(trainData)[!names(trainData) %in% outcomeName]
#predictors.raw <-names(trainData.raw.imputed)[!names(trainData.raw.imputed) %in% outcomeName]

trainData$pressure_sore<-as.factor(trainData$pressure_sore)
#trainData1 <- data.matrix(trainData)
fitControl <- trainControl(
  method = 'cv',                   # k-fold cross validation
  number = 5,                      # number of folds
  savePredictions = 'final',       # saves predictions for optimal tuning parameter
  classProbs = T,                  # should class probabilities be returned
  summaryFunction=twoClassSummary  # results summary function
) 

# By setting the classProbs=T the probability scores are generated instead of directly predicting the class based on a predetermined cutoff of 0.5.  Important for CALIBRATION. 

model_glm<-train(trainData[,predictors],trainData[,outcomeName],method='glm', family='binomial', tuneLength = 5, metric='ROC', trControl = fitControl)
model_rf<-train(trainData[,predictors],trainData[,outcomeName],method='rf',tuneLength = 5, metric='ROC', trControl = fitControl)
model_mars = train(trainData[,predictors],trainData[,outcomeName], method='earth', tuneLength = 5, metric='ROC', trControl = fitControl)
model_svmLin = train(trainData[,predictors],trainData[,outcomeName], method='svmLinear', tuneLength = 5, metric='ROC', trControl = fitControl)
model_svmPoly = train(trainData[,predictors],trainData[,outcomeName], method='svmPoly', tuneLength = 5, metric='ROC', trControl = fitControl)
model_gbm<-train(trainSet[,predictors],trainSet[,outcomeName],method='gbm', tuneLength = 5, metric='ROC', trControl = fitControl)
model_xgb <- train(trainSet[,predictors],trainSet[,outcomeName],method='xgbTree', tuneLength = 5, metric='ROC', trControl = fitControl)
model_nnet<-train(trainSet[,predictors],trainSet[,outcomeName],method='nnet',tuneLength = 5, metric='ROC', trControl = fitControl)

############################################################
library(party)
library(partykit)
control <- ctree_control(testtype = c("Bonferroni", "MonteCarlo", "Univariate", "Teststatistic"),
              pargs = GenzBretz(),alpha = 0.05,
              minbucket = 7L,
              stump = FALSE, lookahead = FALSE, MIA = FALSE, nresample = 9999L,
              mtry = 20, maxdepth = 20)
              
model_ctree = ctree(pressure_sore ~ real_age + ACTIVITY_SCORE +BRADEN_SCORE + factor(ulcer_free_admission.1), 
                    data = trainData, control = control)

model_cforest = cforest(pressure_sore ~ ., 
                    data = trainData)

############################################################
## VISUALIZE MODEL PERFORMANCE ON TRAINING SET 

plot(model_rf)


############################################################

## VARIABLE IMPORTANCE 

plot(model_gbm)

############################################################

## CUSTOM TUNEGRIDS 
xgbGrid <- expand.grid(nrounds = c(1, 10),
                       max_depth = c(1, 4),
                       eta = c(.1, .4),
                       gamma = 0,
                       colsample_bytree = .7,
                       min_child_weight = 1,
                       subsample = c(.8, 1))


############################################################

## CLASS IMBALANCE METHODS
varImp(object=model_rf)

#Plotting Varianle importance for GBM
plot(varImp(object=model_rf),main="RF - Variable Importance")


############################################################

## DIFFERENT RESAMPLING METHODS

cctrl1 <- trainControl(method = "cv", number = 3, returnResamp = "all",
                       classProbs = TRUE, 
                       summaryFunction = twoClassSummary)
cctrl2 <- trainControl(method = "LOOCV",
                       classProbs = TRUE, summaryFunction = twoClassSummary)
cctrl3 <- trainControl(method = "oob")
cctrl4 <- trainControl(method = "none",
                       classProbs = TRUE, summaryFunction = twoClassSummary)
cctrlR <- trainControl(method = "cv", number = 3, returnResamp = "all", search = "random")


############################################################

## PREPROCESS TEST DATA IN EXACTLY THE SAME WAY USING PREPROCESSING MODULES FROM TRAINING SET. 

x.test.preprocess <- predict(preProcess_missingdata_model, newdata = x.test.preprocess)
# Dummy coding
x.test.preprocess<- data.frame(predict(dmy, newdata = x.test.preprocess))
## COMINE AGAIN WITH ICD9 PREDICTORS WHICH DID NOT REQUIRE PREPROCESSING
testData<-cbind(x.test.preprocess,x.test.icd, y.test)
anyNA(testData)


predicted <- predict(model_mars, testData[,predictors])
confusionMatrix(reference = testData[,outcomeName], data = predicted, mode='everything', positive='TEST')

############################################################

## COMPARING MULTIPLE MODEL PERFORMANCE ON TRAINING SET. 

models_compare <- resamples(list(ADABOOST=model_adaboost, RF=model_rf, XGBDART=model_xgbDART, 
                                 MARS=model_mars3, SVM=model_svmRadial))

# Summary of the models performances
summary(models_compare)

# Draw box plots to compare models
scales <- list(x=list(relation="free"), y=list(relation="free"))
bwplot(models_compare, scales=scales)


############################################################

## ENSEMBLE PREDICTIONS 








