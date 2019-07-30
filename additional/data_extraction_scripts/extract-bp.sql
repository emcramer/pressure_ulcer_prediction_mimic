/* Extracts blood pressure chartevent data, removing unnecessary columns to make the data file smaller */
select
	chartevents.subject_id,
	chartevents.hadm_id,
	chartevents.icustay_id,
	chartevents.charttime as charteventsCharttime,
	chartevents.cgid as caregiverID,
	chartevents.itemid as charteventsItemid,
	chartevents.value as charteventsValue,
	chartevents.valuenum as charteventsValueuom
from chartevents
where chartevents.itemid in (3312, 52, 456, 442, 443, 8440, 225312, 225309, 225310);