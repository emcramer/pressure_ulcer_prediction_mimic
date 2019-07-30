/* Extracts creatinine labevent data, removing unnecessary columns to make the data file smaller */
select
	labevents.subject_id,
	labevents.hadm_id,
	labevents.charttime as labeventsCharttime,
	labevents.itemid as labeventsItemid,
	labevents.value as labeventsValue,
	labevents.valuenum as labeventsValueuom
from labevents
where labevents.itemid in (50912, 51082);