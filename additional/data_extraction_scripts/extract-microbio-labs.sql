/* Extracts microbiology labs */
select
	microbiologyevents.subject_id,
	microbiologyevents.hadm_id,
	microbiologyevents.charttime,
	microbiologyevents.spec_itemid,
	microbiologyevents.spec_type_desc,
	microbiologyevents.org_itemid,
	microbiologyevents.org_name
from microbiologyevents
where spec_itemid in (70091, 70012);