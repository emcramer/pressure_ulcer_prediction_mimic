# Mapping of ICD codes to aggregated disease categories - matrix of booleans of whether that disease was recorded in the current admission
# or any previous admission, organized by ICUSTAY_ID

library(dplyr)
library(stringr)

# Load raw ICD features
icd9_features <- read_csv("icd9_feature_matrix_cleaned.csv")

diabetes.icd <- names(icd9_features)[str_detect(names(icd9_features), "250")] 
diabetes_features <- icd9_features %>% select(diabetes.icd)
diabetes_features <- data.frame(diabetes=do.call(pmax,diabetes_features))
diabetes_features$diabetes[is.na(diabetes_features$diabetes)] <- 0 

pvd.icd <- names(icd9_features)[str_detect(names(icd9_features), "443")] 
pvd_features <- icd9_features %>% select(pvd.icd)
pvd_features <- data.frame(pvd=do.call(pmax,diabetes_features))
pvd_features$pvd[is.na(pvd_features$pvd)] <- 0 

amputation.icd <- names(icd9_features)[str_detect(names(icd9_features), "88")] 
amputation_features <- icd9_features %>% select(amputation.icd)
amputation_features <- data.frame(amputation=do.call(pmax,amputation_features))
amputation_features$amputation[is.na(amputation_features$amputation)] <- 0 

sci.icd <- names(icd9_features)[str_detect(names(icd9_features), "95")] 
sci_features <- icd9_features %>% select(sci.icd)
sci_features <- data.frame(sci=do.call(pmax,sci_features))
sci_features$sci[is.na(sci_features$sci)] <- 0 

atherosclerosis.icd <- names(icd9_features)[str_detect(names(icd9_features), "440")] 
atherosclerosis_features <- icd9_features %>% select(atherosclerosis.icd)
atherosclerosis_features <- data.frame(atherosclerosis=do.call(pmax,atherosclerosis_features))
atherosclerosis_features$atherosclerosis[is.na(atherosclerosis_features$atherosclerosis)] <- 0 

leukemia.icd <- c(names(icd9_features)[str_detect(names(icd9_features), "204")],
                  names(icd9_features)[str_detect(names(icd9_features), "205")],
                  names(icd9_features)[str_detect(names(icd9_features), "206")],
                  names(icd9_features)[str_detect(names(icd9_features), "207")],
                  names(icd9_features)[str_detect(names(icd9_features), "208")])
leukemia.icd[str_detect(leukemia.icd,"95")] <- NA
leukemia.icd <- colnames(icd9_features)[colnames(icd9_features) %in% na.omit(leukemia.icd)]
leukemia_features <- icd9_features %>% select(leukemia.icd)
leukemia_features <- data.frame(leukemia=do.call(pmax,leukemia_features))
leukemia_features$leukemia[is.na(leukemia_features$leukemia)] <- 0 

stroke.icd <- names(icd9_features)[str_detect(names(icd9_features), "434")] 
stroke_features <- icd9_features %>% select(stroke.icd)
stroke_features <- data.frame(stroke=do.call(pmax,stroke_features))
stroke_features$stroke[is.na(stroke_features$stroke)] <- 0 

chf.icd <- names(icd9_features)[str_detect(names(icd9_features), "428")] 
chf_features <- icd9_features %>% select(chf.icd)
chf_features <- data.frame(chf=do.call(pmax,chf_features))
chf_features$chf[is.na(chf_features$chf)] <- 0 

anemia.icd <- c(names(icd9_features)[str_detect(names(icd9_features), "280")],
                names(icd9_features)[str_detect(names(icd9_features), "285")],
                names(icd9_features)[str_detect(names(icd9_features), "281")])
anemia.icd[str_detect(anemia.icd,"42")] <- NA
anemia.icd <- colnames(icd9_features)[colnames(icd9_features) %in% na.omit(anemia.icd)]
anemia_features <- icd9_features %>% select(anemia.icd)
anemia_features <- data.frame(anemia=do.call(pmax,anemia_features))
anemia_features$anemia[is.na(anemia_features$anemia)] <- 0

neuropathy.icd <- names(icd9_features)[str_detect(names(icd9_features), "356")|str_detect(names(icd9_features), "357")] 
neuropathy_features <- icd9_features %>% select(neuropathy.icd)
neuropathy_features <- data.frame(neuropathy=do.call(pmax,neuropathy_features))
neuropathy_features$neuropathy[is.na(neuropathy_features$neuropathy)] <- 0 

icd9_combined <- cbind(diabetes_features,pvd_features,amputation_features,sci_features,
                       atherosclerosis_features,leukemia_features,stroke_features,chf_features,
                       anemia_features,neuropathy_features)

icd9_features <- cbind(icd9_features$ICUSTAY_ID, data.frame(lapply(icd9_combined, factor)))

write.csv(icd9_features, 'icd9_feature_matrix_cleaned.csv')
