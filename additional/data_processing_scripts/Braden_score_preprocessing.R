# CALCULATE AND CLEAN BRADEN SCORES AVAILABLE WITHIN FIRST 24HRS. 

library(dplyr)
library(ggplot)
library(stringr)

master <- read_csv("cases_controls_master_stage_2.csv", 
                           col_types = cols(DOB = col_skip(), DOD = col_skip(), 
                                            INTIME = col_datetime(format = "%Y-%m-%d %H:%M:%S"), 
                                            OUTTIME = col_datetime(format = "%Y-%m-%d %H:%M:%S"), 
                                            ROW_ID = col_skip(), X1 = col_skip(), 
                                            admittime = col_datetime(format = "%Y-%m-%d %H:%M:%S")))
Sys.setenv(TZ='UTC')

#############################################################
braden <- read_delim("Downloads/bradenchartevents", 
                     "|", escape_double = FALSE, col_types = cols(charteventscharttime = col_datetime(format = "%Y-%m-%d %H:%M:%S")), 
                     trim_ws = TRUE)
braden <- braden[-1,]

score_table <- braden %>% group_by(charteventsitemid) %>% summarise(count=n(), distint_pts = n_distinct(subject_id)) 
score_table
braden <- braden %>% inner_join(select(master,ICUSTAY_ID,INTIME), by=c('icustay_id'='ICUSTAY_ID'))
braden <- braden %>% mutate(delta = as.numeric(difftime(charteventscharttime,INTIME,units='days')))
braden <- filter(braden, delta <20 & delta >-1)
hist(braden$delta)

#############################################################
# Filter braden scores to within 24hrs of admission. 
braden.filtered <- filter(braden, delta>=0 & delta <=1)
braden.measured <- braden.filtered %>% filter(charteventsitemid==87) %>% distinct(icustay_id) 
braden.measured <- braden.measured %>% mutate(braden.measured = 1)

braden.filtered <- braden.filtered %>% arrange(desc(charteventscharttime), by_group=icustay_id)

### CAREVUE ### 
braden.scores <- braden.filtered %>% filter(charteventsitemid==87 & !is.na(charteventsvalueuom)) %>% group_by(icustay_id) %>% summarise(braden.score=charteventsvalueuom[1])
braden.activity <- braden.filtered %>% filter(charteventsitemid==82 & !is.na(charteventsvalue)) %>% group_by(icustay_id) %>% summarise(activity=charteventsvalue[1])
braden.mobility <- braden.filtered %>% filter(charteventsitemid==84 & !is.na(charteventsvalue)) %>% group_by(icustay_id) %>% summarise(mobility=charteventsvalue[1])
braden.nutrition <- braden.filtered %>% filter(charteventsitemid==86 & !is.na(charteventsvalue)) %>% group_by(icustay_id) %>% summarise(nutrition=charteventsvalue[1])
braden.shear <- braden.filtered %>% filter(charteventsitemid==83 & !is.na(charteventsvalue)) %>% group_by(icustay_id) %>% summarise(shear=charteventsvalue[1])
braden.moisture <- braden.filtered %>% filter(charteventsitemid==85 & !is.na(charteventsvalue)) %>% group_by(icustay_id) %>% summarise(moisture=charteventsvalue[1])
braden.sensory <- braden.filtered %>% filter(charteventsitemid==88 & !is.na(charteventsvalue)) %>% group_by(icustay_id) %>% summarise(sensory=charteventsvalue[1])

### METAVISION  ###
braden.sensory.2 <- braden.filtered %>% filter(charteventsitemid==224054 & !is.na(charteventsvalue)) %>% group_by(icustay_id) %>% summarise(sensory.2=charteventsvalue[1])
braden.moisture.2 <- braden.filtered %>% filter(charteventsitemid==224055 & !is.na(charteventsvalue)) %>% group_by(icustay_id) %>% summarise(moisture.2=charteventsvalue[1])
braden.activity.2 <- braden.filtered %>% filter(charteventsitemid==224056 & !is.na(charteventsvalue)) %>% group_by(icustay_id) %>% summarise(activity.2=charteventsvalue[1])
braden.mobility.2 <- braden.filtered %>% filter(charteventsitemid==224057 & !is.na(charteventsvalue)) %>% group_by(icustay_id) %>% summarise(mobility=charteventsvalue[1],sensory.score=charteventsvalueuom[1])
braden.nutrition.2 <- braden.filtered %>% filter(charteventsitemid==224058 & !is.na(charteventsvalue)) %>% group_by(icustay_id) %>% summarise(nutrition=charteventsvalue[1],sensory.score=charteventsvalueuom[1])
braden.shear.2 <- braden.filtered %>% filter(charteventsitemid==224059 &  !is.na(charteventsvalue)) %>% group_by(icustay_id) %>% summarise(shear=charteventsvalue[1],sensory.score=charteventsvalueuom[1])

# Only activity, moisture & sensory are populated. 

#############################################################

nrow(braden.activity)
nrow(master)

master.braden <- master %>% select(ICUSTAY_ID) %>% left_join(braden.scores, by=c('ICUSTAY_ID'='icustay_id')) %>% 
  left_join(braden.activity, by=c('ICUSTAY_ID'='icustay_id')) %>% 
  left_join(braden.mobility, by=c('ICUSTAY_ID'='icustay_id')) %>% 
  left_join(braden.nutrition, by=c('ICUSTAY_ID'='icustay_id'))%>% 
  left_join(braden.shear, by=c('ICUSTAY_ID'='icustay_id'))%>% 
  left_join(braden.moisture, by=c('ICUSTAY_ID'='icustay_id'))%>% 
  left_join(braden.sensory, by=c('ICUSTAY_ID'='icustay_id'))%>% 
  left_join(braden.activity.2, by=c('ICUSTAY_ID'='icustay_id'))%>% 
  left_join(braden.moisture.2, by=c('ICUSTAY_ID'='icustay_id'))%>% 
  left_join(braden.sensory.2, by=c('ICUSTAY_ID'='icustay_id'))

# ACTIVITY
master.braden$ACTIVITY_SCORE <- NA
master.braden <- master.braden %>% mutate(ACTIVITY_SCORE = ifelse(str_detect(activity,"Bed")|str_detect(activity,"Bed"),1,ACTIVITY_SCORE))
master.braden <- master.braden %>% mutate(ACTIVITY_SCORE = ifelse(str_detect(activity,"Chair")|str_detect(activity,"Chair"),2,ACTIVITY_SCORE))
master.braden <- master.braden %>% mutate(ACTIVITY_SCORE = ifelse(str_detect(activity,"Occasional")|str_detect(activity,"Occasional"),3,ACTIVITY_SCORE))
master.braden <- master.braden %>% mutate(ACTIVITY_SCORE = ifelse(str_detect(activity,"Frequently")|str_detect(activity,"Frequently"),4,ACTIVITY_SCORE))

# MOISTURE
master.braden <- master.braden %>% mutate(MOISTURE_SCORE1 = ifelse(str_detect(moisture,"Consist")|str_detect(moisture.2,"Consist"),1,0))
master.braden <- master.braden %>% mutate(MOISTURE_SCORE2 = ifelse(moisture=="Moist"|moisture.2=="Moist",2,0))
master.braden <- master.braden %>% mutate(MOISTURE_SCORE3 = ifelse(str_detect(moisture,"Occ")|str_detect(moisture.2,"Occ"),3,0))
master.braden <- master.braden %>% mutate(MOISTURE_SCORE4 = if_else((str_detect(moisture,"Rarely") | str_detect(moisture.2,"Rarely")),4,0))
master.braden <- master.braden %>%  mutate(MOISTURE_SCORE = pmax(MOISTURE_SCORE1,MOISTURE_SCORE2,MOISTURE_SCORE3,MOISTURE_SCORE4, na.rm = TRUE))
master.braden <- select(master.braden,-MOISTURE_SCORE1,-MOISTURE_SCORE2, -MOISTURE_SCORE3, -MOISTURE_SCORE4)    

# SENSORY
master.braden <- master.braden %>% mutate(SENSORY_SCORE1 = ifelse(str_detect(sensory,"Comp")|str_detect(sensory.2,"Comp"),1,0))
master.braden <- master.braden %>% mutate(SENSORY_SCORE2 = ifelse(str_detect(sensory,"Very")|str_detect(sensory.2,"Very"),2,0))
master.braden <- master.braden %>% mutate(SENSORY_SCORE3 = ifelse(str_detect(sensory,"Sl")|str_detect(sensory.2,"Sl"),3,0))
master.braden <- master.braden %>% mutate(SENSORY_SCORE4 = ifelse(str_detect(sensory,"No")|str_detect(sensory.2,"No"),4,0))
master.braden <- master.braden %>%  mutate(SENSORY_SCORE = pmax(SENSORY_SCORE1,SENSORY_SCORE2,SENSORY_SCORE3,SENSORY_SCORE4, na.rm = TRUE))
master.braden <- select(master.braden,-SENSORY_SCORE1,-SENSORY_SCORE2, -SENSORY_SCORE3, -SENSORY_SCORE4) 

# SHEAR 
master.braden$SHEAR_SCORE <- NA
master.braden <- master.braden %>% mutate(SHEAR_SCORE = ifelse(shear=="Problem",1,SHEAR_SCORE))
master.braden <- master.braden %>% mutate(SHEAR_SCORE = ifelse(shear=="Potential Prob",2,SHEAR_SCORE))
master.braden <- master.braden %>% mutate(SHEAR_SCORE = ifelse(shear=="No Apparent Prob",3,SHEAR_SCORE))

# NUTRITION 
master.braden$NUTRITION_SCORE <- NA
master.braden <- master.braden %>% mutate(NUTRITION_SCORE = ifelse(nutrition=="Very Poor",1,NUTRITION_SCORE))
master.braden <- master.braden %>% mutate(NUTRITION_SCORE = ifelse(nutrition=="Prob. Inadequate",2,NUTRITION_SCORE))
master.braden <- master.braden %>% mutate(NUTRITION_SCORE = ifelse(nutrition=="Adequate",3,NUTRITION_SCORE))
master.braden <- master.braden %>% mutate(NUTRITION_SCORE = ifelse(nutrition=="Excellent",4,NUTRITION_SCORE))

# MOBILITY 
master.braden$MOBILITY_SCORE <- NA
master.braden <- master.braden %>% mutate(MOBILITY_SCORE = ifelse(mobility=="Comp. Immobile",1,MOBILITY_SCORE))
master.braden <- master.braden %>% mutate(MOBILITY_SCORE= ifelse(mobility=="Very Limited",2,MOBILITY_SCORE))
master.braden <- master.braden %>% mutate(MOBILITY_SCORE = ifelse(mobility=="Sl. Limited",3,MOBILITY_SCORE))
master.braden <- master.braden %>% mutate(MOBILITY_SCORE = ifelse(mobility=="No Limitations",4,MOBILITY_SCORE))

master.braden <- master.braden %>% mutate(BRADEN_SCORE = braden.score) %>% select(ICUSTAY_ID, BRADEN_SCORE, MOISTURE_SCORE, ACTIVITY_SCORE, MOBILITY_SCORE, SENSORY_SCORE, NUTRITION_SCORE, SHEAR_SCORE) 

write.csv(master.braden,'braden_scores_v2.csv')
