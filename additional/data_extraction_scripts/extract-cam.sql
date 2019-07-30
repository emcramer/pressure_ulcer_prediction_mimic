/* Extracts confusion assessment method chartevent data, removing unnecessary columns to make the data file smaller 

-> This was only available in metavision

*/
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
where chartevents.itemid in (228300, 228301, 228302, 228303, 228334, 228335, 228336, 228337);