/* Extracts o2sat chartevent data, removing unnecessary columns to make the data file smaller */
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
where chartevents.itemid in (778, 3784, 220235, 779, 3785, 220224, 3830, 823, 3831, 4203, 646, 220277, 834);