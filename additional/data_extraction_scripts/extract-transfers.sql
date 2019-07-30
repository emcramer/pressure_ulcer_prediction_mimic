/* Extracts transfer and ICU admission information */
select
	transfers.subject_id,
	transfers.hadm_id,
	transfers.icustay_id,
	transfers.prev_wardid,
	transfers.curr_wardid,
	transfers.intime,
	transfers.outtime,
	transfers.los
from transfers;