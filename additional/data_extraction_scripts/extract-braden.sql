/* Extracts Braden Score chartevent data, removing unnecessary columns to make the data file smaller */
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
where chartevents.itemid in (82, 83, 84, 85, 86, 87, 88, 224054, 224055, 224056);