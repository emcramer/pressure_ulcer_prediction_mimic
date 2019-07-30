/* Extracts relevant lab results */
select
	labevents.subject_id,
	labevents.hadm_id,
	labevents.charttime as labeventsCharttime,
	labevents.itemid as labeventsItemid,
	labevents.value as labeventsValue,
	labevents.valuenum as labeventsValuenum,
	labevents.valueuom as labeventsValueuom
from labevents
where labevents.itemid in (50883,50884,50885,50912,50824,50983,50822,50971,50889,51288,51002,51003,50852, 50931, 50809, 51237,51006,50963,51301,51265,51256,50886,50862,51486,51069,51487,51084, 51478);