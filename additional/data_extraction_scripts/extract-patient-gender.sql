/* Extracts patient gender data, removing unnecessary columns to make the data file smaller */
select
	patients.subject_id,
	patients.gender
from patients;