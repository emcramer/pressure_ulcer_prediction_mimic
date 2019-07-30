#!/bin/sh
export PGPASSWORD='postgres'; 
export PGOPTIONS='--search_path=mimiciii';

# Extracting the PU chartevents
psql -U postgres -d mimic -f extract-pu.sql | gzip -9 > data/raw_data_20180529/puchartevents.gz;

# Extracting the Hematocrit chartevents
psql -U postgres -d mimic -f extract-hematocrit.sql | gzip -9 > data/raw_data_20180529/hematocritchartevents.gz;

# Extracting the Hemoglobin chartevents
psql -U postgres -d mimic -f extract-hemoglobin.sql | gzip -9 > data/raw_data_20180529/hemoglobinchartevents.gz;

# Extracting the oxygen saturation chartevents
psql -U postgres -d mimic -f extract-o2sat.sql | gzip -9 > data/raw_data_20180529/o2satchartevents.gz;

# Extracting the blood pressure chartevents
psql -U postgres -d mimic -f extract-bp.sql | gzip -9 > data/raw_data_20180529/bpchartevents.gz;

# Extracting the glasgow coma scale chartevents
psql -U postgres -d mimic -f extract-gcs.sql | gzip -9 > data/raw_data_20180529/gcschartevents.gz;

# Extracting the confusion assessment method chartevents
psql -U postgres -d mimic -f extract-cam.sql | gzip -9 > data/raw_data_20180529/camchartevents.gz;

# Extracting the confusion assessment method chartevents
psql -U postgres -d mimic -f extract-prd.sql | gzip -9 > data/raw_data_20180529/prdchartevents.gz;

# Extracting the confusion assessment method chartevents
psql -U postgres -d mimic -f extract-gucatheter.sql | gzip -9 > data/raw_data_20180529/gucatheterdatetimeevents.gz;

# Extracting the albumin chartevents
psql -U postgres -d mimic -f extract-albumin.sql | gzip -9 > data/raw_data_20180529/albuminchartevents.gz;

# Extracting the ventilator(mode) chartevents
psql -U postgres -d mimic -f extract-ventilator.sql | gzip -9 > data/raw_data_20180529/ventilatorchartevents.gz;

# Extracting the creatinine chartevents
psql -U postgres -d mimic -f extract-creatinine.sql | gzip -9 > data/raw_data_20180529/creatininechartevents.gz;

# Extracting the creatinine chartevents
psql -U postgres -d mimic -f extract-labcreatinine.sql | gzip -9 > data/raw_data_20180529/creatininelabevents.gz;

# Extracting the heart rate chartevents
psql -U postgres -d mimic -f extract-hr.sql | gzip -9 > data/raw_data_20180529/hrchartevents.gz;

# Extracting the wbc chartevents
psql -U postgres -d mimic -f extract-wbc.sql | gzip -9 > data/raw_data_20180529/wbcchartevents.gz;

# Extracting the bilirubin chartevents
psql -U postgres -d mimic -f extract-bilirubin.sql | gzip -9 > data/raw_data_20180529/bilirubinchartevents.gz;

# Extracting the bilirubin chartevents
psql -U postgres -d mimic -f extract-labbilirubin.sql | gzip -9 > data/raw_data_20180529/bilirubinclabevents.gz;

# Extracting the glucose chartevents
psql -U postgres -d mimic -f extract-glucose.sql | gzip -9 > data/raw_data_20180529/glucosechartevents.gz;

# Extracting the wbc chartevents
psql -U postgres -d mimic -f extract-inr.sql | gzip -9 > data/raw_data_20180529/inrchartevents.gz;

# Extracting the wbc chartevents
psql -U postgres -d mimic -f extract-bun.sql | gzip -9 > data/raw_data_20180529/bunchartevents.gz;

# Extracting the BNP chartevents
psql -U postgres -d mimic -f extract-bnp.sql | gzip -9 > data/raw_data_20180529/bnpchartevents.gz;

# Extracting the troponin chartevents
psql -U postgres -d mimic -f extract-troponin.sql | gzip -9 > data/raw_data_20180529/troponinchartevents.gz;

# Extracting the wbc chartevents
psql -U postgres -d mimic -f extract-totalprotein.sql | gzip -9 > data/raw_data_20180529/totalproteinchartevents.gz;

# extracting the admissions data
psql -U postgres -d mimic -f extract-admissions.sql | gzip -9 > data/raw_data_20180529/admissions.gz;

# extracting the labevents
psql -U postgres -d mimic -f extract-labevents.sql | gzip -9 > data/raw_data_20180529/labevents.gz;

# extracting prescriptions
psql -U postgres -d mimic -f extract-prescriptions.sql | gzip -9 > data/raw_data_20180529/vasoactive_prescriptions.gz;

# Extracting the patient gender data
psql -U postgres -d mimic -f extract-patient-gender.sql | gzip -9 > data/raw_data_20180529/patientgenders.gz;

# Extracting microbiology lab data
psql -U postgres -d mimic -f extract-microbio-labs.sql | gzip -9 > data/raw_data_20180529/microbio-labs.gz;

# Extracting temperature data
psql -U postgres -d mimic -f extract-temperature.sql | gzip -9 > data/raw_data_20180529/tempchartevents.gz;

# Extracting height and weight data
psql -U postgres -d mimic -f extract-hw.sql | gzip -9 > data/raw_data_20180529/hwchartevents.gz;

# Extracting Braden Score data
psql -U postgres -d mimic -f extract-braden.sql | gzip -9 > data/raw_data_20180529/bradenchartevents.gz;