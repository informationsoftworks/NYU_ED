select t.*,
	coalesce(edcnnpa, 0) as edcnnpa,
	coalesce(edcnpa, 0) as edcnpa,
	coalesce(epct, 0) as epct,
	coalesce(noner, 0) as noner,
	coalesce(alcohol, 0) as alcohol,
	coalesce(drug, 0) as drug,
	coalesce(injury, 0) as injury,
	coalesce(psych, 0) as psych,
	coalesce(unc, 1) as unc
from my_source_data t -- REPLACE "my_source_data" WITH NAME OF TABLE CONTINING DISCHARGE INFORMATION
left join nyu_ed_scores n
  on t.dx = n.dx
;
