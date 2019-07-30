/* Extracts icd9 diagnosis data, removing unnecessary columns to make the data file smaller */
select
	diagnoses_icd.subject_id ,
	diagnoses_icd.hadm_id,
	diagnoses_icd.icd9_code
from diagnoses_icd

-- getting spinal cord injury codes --
where diagnoses_icd.icd9_code like '952%' or
diagnoses_icd.icd9_code like '953%' or

-- getting peripheral vascular disease codes --
diagnoses_icd.icd9_code like '443%' or

-- getting amputation codes --
diagnoses_icd.icd9_code like '886%' or
diagnoses_icd.icd9_code like '887%' or
diagnoses_icd.icd9_code like '895%' or

-- getting diabetes codes --
diagnoses_icd.icd9_code like '250%' or

-- getting athersclerosis codes --
diagnoses_icd.icd9_code like '440%' or

-- getting leukemia codes --
diagnoses_icd.icd9_code like '204%' or
diagnoses_icd.icd9_code like '205%' or
diagnoses_icd.icd9_code like '206%' or
diagnoses_icd.icd9_code like '207%' or
diagnoses_icd.icd9_code like '208%' or

-- getting stroke codes --
diagnoses_icd.icd9_code like '4349%' or

-- getting congestive heart failure codes --
diagnoses_icd.icd9_code like '428%' or

-- getting anemia codes --
diagnoses_icd.icd9_code like '280%' or
diagnoses_icd.icd9_code like '2859' or
diagnoses_icd.icd9_code like '281%' or

-- getting neurposthay codes --
diagnoses_icd.icd9_code like '356%' or
diagnoses_icd.icd9_code like '357%';