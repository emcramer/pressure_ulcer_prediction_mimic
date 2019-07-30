/* Extracts bilirubin chartevent data, removing unnecessary columns to make the data file smaller
	*** ONLY CONTAINS METAVISION DTA!!! ***
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
where chartevents.itemid in (225690);