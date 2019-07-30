
#### ALTERNATE COHORT -> Include patients who had a Stage 1 pressure ulcer recorded within the first 24hrs, who then went on to develop Stage 2. 

library(readr)
library(dplyr)
Sys.setenv(TZ='UTC')

#################################################################################
# Load the data 

#Load PU data from CHARTEVENTS
puchartevents <- read_delim("Downloads/mimic_data_final/puchartevents.txt", 
                            "|", escape_double = FALSE, col_types = cols(charteventscharttime = col_datetime(format = "%Y-%m-%d %H:%M:%S"), 
                            charteventsvalueuom = col_skip()), 
                            trim_ws = TRUE)
puchartevents <- puchartevents[-1,]

#Load admissions data from ADMISSIONS
admissions <- read_delim("Downloads/mimic_data_final/admissions.txt", 
                          "|", escape_double = FALSE, col_types = cols(age = col_number()), 
                          trim_ws = TRUE)
admissions <- admissions[-1,]
admissions$subject_id <- as.numeric(admissions$subject_id)

#Load ICU stay data from ICUSTAYS
icustays <- read_csv("Downloads/mimic_data_final/ICUSTAYS.csv", 
                     col_types = cols(INTIME = col_datetime(format = "%Y-%m-%d %H:%M:%S"), 
                                            OUTTIME = col_datetime(format = "%Y-%m-%d %H:%M:%S")))


#Load patient data from PATIENTS
PATIENTS <- read_csv("Downloads/mimic_data_final/PATIENTS.csv")

#################################################################################
# Convert charteventsvalue (description) to grade based on NPUAP criteria 
# https://www.uptodate.com/contents/image?imageKey=PC%2F62903&topicKey=SURG%2F2887&source=see_link

puchartevents <- puchartevents %>% 
                    dplyr::mutate(stage=ifelse(charteventsvalue=='Intact,Color Chg',1,NA),
                           stage=ifelse(charteventsvalue=='Unable to Stage','Unstageable',stage), 
                           stage=ifelse(charteventsvalue=='Red, Unbroken',1,stage),
                           stage=ifelse(charteventsvalue=='Through Dermis',2,stage),
                           stage=ifelse(charteventsvalue=='Through Fascia',3,stage),
                           stage=ifelse(charteventsvalue=='Other/Remarks',NA,stage),
                           stage=ifelse(charteventsvalue=='To Bone',4,stage),
                           stage=ifelse(charteventsvalue=='Part. Thickness',2,stage),
                           stage=ifelse(charteventsvalue=='Full Thickness',3,stage),
                           stage=ifelse(charteventsvalue=='Deep Tiss Injury','DTI',stage),
                           stage=ifelse(charteventsvalue=='Not applicable',NA,stage),
                           stage=ifelse(charteventsvalue=='Red; unbroken',1,stage),
                           stage=ifelse(charteventsvalue=='Partial thickness skin loss through epidermis and/or dermis; ulcer may present as an abrasion, blister, or shallow crater',2,stage),
                           stage=ifelse(charteventsvalue=='Full thickness skin loss that may extend down to underlying fascia; ulcer may have tunneling or undermining',3,stage),
                           stage=ifelse(charteventsvalue=='Full thickness skin loss with damage to muscle, bone, or supporting structures; tunneling or undermining may be present',4,stage),
                           stage=ifelse(charteventsvalue=='Unable to stage; wound is covered with eschar','Unstageable',stage),
                           stage=ifelse(charteventsvalue=='Deep tissue injury','DTI',stage))


unique(puchartevents$stage)

puchartevents$stage_1 <- puchartevents$stage

# Unstageable cast to 3
puchartevents <- puchartevents %>% dplyr::mutate(stage_1=ifelse(stage_1=='DTI',1,stage_1), stage_1=ifelse(stage_1=='Unstageable',3,stage_1))
puchartevents$stage_1 <- as.numeric(puchartevents$stage_1)

#################################################################################
# Create summary metrics for pressure ulcers per ICU stay

# Filter NA recording as they are indecipherable - ?data not entered / ?ulcer healed 
puchartevents <- filter(puchartevents, !is.na(stage_1))

# Create dummy stage variable where we only keep PUs at stage 2 or above 
puchartevents$stage_2 <- puchartevents$stage_1

puchartevents.2 <- filter(puchartevents, stage_2>=2)

puchartevents_grouped.2 <- puchartevents.2 %>% dplyr::arrange(icustay_id,charteventscharttime) %>% 
  dplyr::group_by(icustay_id) %>%
  dplyr::summarise(time_of_stage_2=charteventscharttime[1], stage_2=1)

puchartevents_grouped <- puchartevents %>% dplyr::arrange(icustay_id,charteventscharttime) %>% 
  dplyr::group_by(icustay_id) %>%
  dplyr::summarise(first_recorded=charteventscharttime[1],max_stage=max(stage_1,na.rm = TRUE),
            record_count=n(), last_stage=last(stage_1), first_stage=first(stage_1))

puchartevents_grouped <- puchartevents_grouped %>% mutate(diff_stage=last_stage-first_stage)

str(puchartevents_grouped)

nrow(puchartevents_grouped)

# 6269 distinct ICU stays with pressure sore recorded

#################################################################################
# Combine summary metrics with all ICU stays

icu_stays_pu <- icustays %>% left_join(puchartevents_grouped, by = c('ICUSTAY_ID'='icustay_id')) %>% left_join(puchartevents_grouped.2, by = c('ICUSTAY_ID'='icustay_id'))
#icu_stays_pu <- icu_stays_pu %>% mutate(pressure_sore = ifelse(is.na(first_recorded),0,1))
icu_stays_pu <- icu_stays_pu %>% mutate(time_to_onset=difftime(time_of_stage_2,INTIME, unit="days"))
icu_stays_pu <- icu_stays_pu %>% mutate(time_to_stage_1=difftime(first_recorded,INTIME, unit="days"))
icu_stays_pu <- icu_stays_pu %>% left_join(select(admissions,hadm_id,admittime,ethnicity,insurance), by=c('HADM_ID'='hadm_id'))
icu_stays_pu <- icu_stays_pu %>% left_join(select(PATIENTS,SUBJECT_ID,GENDER,DOB,DOD,EXPIRE_FLAG), by='SUBJECT_ID')
icu_stays_pu <- icu_stays_pu %>% mutate(stage_1_in_24h=ifelse(as.numeric(time_to_stage_1)<1,1,0))
icu_stays_pu$stage_2[is.na(icu_stays_pu$stage_2)] <- 0
colnames(icu_stays_pu)[20] <- 'pressure_sore'
###################################################################################
# Filter for patients 18yrs and older

icu_stays_pu <- icu_stays_pu %>% mutate(age=round(as.numeric(admittime-DOB, units='days')/365.242,1))
icu_stays_pu <- icu_stays_pu %>% filter(age>=18)
# write.csv(icu_stays_pu,'icustays_pu.csv', row.names = FALSE)

###################################################################################
# Patient numbers by pressure sore first recording 
 icu_stays_pu %>% filter(pressure_sore==1, time_to_onset>=2) %>% nrow()
# 875 distinct patient stays where pressure sore not observed in first 48hours and then recorded. 

icu_stays_pu %>% filter(pressure_sore==1, time_to_onset>=2) %>% distinct(subject_id) %>% nrow()
#874 distinct patients 

icu_stays_pu %>% filter(pressure_sore==1, time_to_onset<2) %>% nrow()
# 1622

icu_stays_pu %>% filter(pressure_sore==1, time_to_onset>1) %>%  nrow()
# 1147

icu_stays_pu %>% filter(pressure_sore==1, time_to_onset>1) %>% distinct(subject_id) %>% nrow()
# 1145

##########################################################################

# DECISION - CASES = patients with pressure sore onset >=1 

##########################################################################
# Ulcer free prior admissions - for both cases and controls

## CASES ## 

cases <- icu_stays_pu %>% filter(pressure_sore==1, time_to_onset>1)
cases <- cases %>% mutate(real_age = ifelse(age>=300, 90, age))
controls <-  filter(icu_stays_pu, pressure_sore==0) 
prior_admissions <- inner_join(select(cases,SUBJECT_ID, HADM_ID, INTIME), select(controls, SUBJECT_ID, HADM_ID, INTIME), by='SUBJECT_ID')
prior_admissions <- prior_admissions %>% mutate(ulcer_free_admission = ifelse(INTIME.x>INTIME.y,1,0))

prior_admissions_grouped <- prior_admissions %>% group_by(SUBJECT_ID) %>% summarise(ulcer_free_admission = max(ulcer_free_admission))
sum(prior_admissions_grouped$ulcer_free_admission)

# Join with icu_stays_pu as an extra variable 
cases <- cases %>% left_join(prior_admissions_grouped, by='SUBJECT_ID')
cases <- cases %>% mutate(ulcer_free_admission = ifelse(is.na(ulcer_free_admission),0,ulcer_free_admission))

## CONTROLS ## 
#controls <-  filter(icu_stays_pu, pressure_sore==0) %>% distinct(SUBJECT_ID, INTIME)

prior_admissions_controls <- controls %>% group_by(SUBJECT_ID) %>% summarise(first_date = min(INTIME))
prior_admissions_controls <- controls %>% left_join(prior_admissions_controls, by='SUBJECT_ID')
prior_admissions_controls <- prior_admissions_controls %>% mutate(ulcer_free_admission=ifelse(INTIME==first_date,0,1))
controls <- controls %>% left_join(select(prior_admissions_controls,ICUSTAY_ID,ulcer_free_admission), by='ICUSTAY_ID')
controls <- controls %>% mutate(real_age = ifelse(age>=300, 90, age))

# COUNT CASES AND CONTROLS
controls %>% distinct(ICUSTAY_ID) %>% nrow()
# 57356
controls %>% distinct(SUBJECT_ID) %>% nrow()
# 44621

cases %>% distinct(ICUSTAY_ID) %>% nrow()
# 1455
cases %>% distinct(SUBJECT_ID) %>% nrow()
# 1395 

##################################################

# Calculate descriptive stats for cases and controls before filtering for time window 

library(matrixStats)
colSds(as.matrix(select(cases,real_age)))
colMeans(as.matrix(select(cases,real_age)))

colSds(as.matrix(select(cases,LOS)))
# 14
colMeans(as.matrix(select(cases,LOS)))
# 11.4 

cases %>% group_by(GENDER) %>% summarise(count=n_distinct())
#1 F       1062
#2 M       1433

cases%>% group_by(EXPIRE_FLAG) %>% summarise(count=n())
cases%>% group_by(twelveMoMortality) %>% summarise(count=n_distinct(SUBJECT_ID))
#           0   520
#           1  1975

controls %>% group_by(GENDER) %>% summarise(count=n_distinct(SUBJECT_ID))
controls %>% group_by(EXPIRE_FLAG) %>% summarise(count=n_distinct(SUBJECT_ID))
controls %>% group_by(twelveMoMortality) %>% summarise(count=n_distinct(SUBJECT_ID))

#           0 28705
#           1 22135

colSds(as.matrix(select(controls,LOS)), na.rm = TRUE)
# 5.2
colMeans(as.matrix(select(controls,LOS)),na.rm = TRUE)
# 3.8

colSds(as.matrix(select(controls,real_age)), na.rm = TRUE)
# 17.1
colMeans(as.matrix(select(controls,real_age)),na.rm = TRUE)
#   63.8

colSds(as.matrix(select(controls,real_age)))
colMeans(as.matrix(select(controls,real_age)))


###############################################################################
# Distinct patients vs distinct ICU stays

cases %>% distinct(SUBJECT_ID) %>% nrow()
# 2014
controls %>% distinct(SUBJECT_ID) %>% nrow()
# 37323

t.test(cases_all$LOS, controls$LOS)
#Welch Two Sample t-test

#data:  cases_all$LOS and controls$LOS
#t = 26.917, df = 2528, p-value < 2.2e-16
#alternative hypothesis: true difference in means is not equal to 0
#95 percent confidence interval:
#  7.045138 8.152288
#sample estimates:
#  mean of x mean of y 
#11.388982  3.790269 



#####################################################################

# Filter by survival time
cases <- cases %>% mutate(survival_days = difftime(DOD,OUTTIME,units='days'))
cases <- cases %>% mutate(twelveMoMortality = ifelse(survival_days<=365,1,0))
cases$twelveMoMortality[is.na(cases$twelveMoMortality)] <- 0
controls <- controls %>% mutate(survival_days = difftime(DOD,OUTTIME,units='weeks'))
controls <- controls %>% mutate(twelveMoMortality = ifelse(survival_days<=365,1,0))
controls$twelveMoMortality[is.na(controls$twelveMoMortality)] <- 0

#cases$stage2PU <- 1
#controls$stage2PU <- 0



cases_controls_master <- rbind(cases,controls)
cases_controls_master <- select(cases_controls_master, -time_to_stage_1)

colnames(cases_controls_master)[19] <- c("first_recorded")
#test <- cases_controls_master %>% select(ICUSTAY_ID,INTIME,DOD) %>% left_join(select(cases_controls, ICUSTAY_ID, INTIME,DOD), by="ICUSTAY_ID")
#test <- test %>% mutate (dod=difftime(DOD.x,DOD.y),intime=difftime(INTIME.x,INTIME.y))
#filter(test, intime >100)

write.csv(cases_controls_master,"cases_controls_master_stage_2.csv")
