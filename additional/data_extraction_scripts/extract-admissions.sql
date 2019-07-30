/* Extracts patient demographic and admission information */
select
	admissions.subject_id,
	admissions.hadm_id,
	admissions.admittime,
	admissions.marital_status,
	admissions.ethnicity,
	admissions.diagnosis,
	admissions.insurance,
	admissions.religion,
	admissions.admittime - patients.dob as age
from admissions
full outer join patients on admissions.subject_id = patients.subject_id;