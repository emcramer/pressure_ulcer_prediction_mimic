/* Extracts pressure reduction device chartevent data, removing unnecessary columns to make the data file smaller */
select
	datetimeevents.subject_id,
	datetimeevents.hadm_id,
	datetimeevents.icustay_id,
	datetimeevents.itemid,
	datetimeevents.charttime,
	datetimeevents.cgid
from datetimeevents
where datetimeevents.itemid in (207, 224017);