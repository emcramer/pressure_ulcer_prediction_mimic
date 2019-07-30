/* Extracts prescription data for all patients with vasoactive medications */
select
	prescriptions.subject_id,
	prescriptions.hadm_id,
	prescriptions.icustay_id,
	prescriptions.startdate as prescriptionStartdate,
	prescriptions.enddate as prescriptionEnddate,
	prescriptions.drug,
	prescriptions.drug_type,
	prescriptions.ndc
	from prescriptions
	where prescriptions.drug like '%Epinephrine%' or 
		prescriptions.drug like '%Norepinephrine%' or 
		prescriptions.drug like '%Phenylephrine HCI%' or
		prescriptions.drug like '%Vasopressin%' or 
		prescriptions.drug like '%Dobutamine%' or
		prescriptions.drug like '%Dopamine%';