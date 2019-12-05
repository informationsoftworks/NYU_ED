drop table if exists nyued_original;
create table nyued_original as
select n.dx, trim(label) as dxname, trim(label) as dxshort, 
	coalesce(xed4,0) as edcnnpa, coalesce(xed3,0) as edcnpa, coalesce(xed2,0) as epct, coalesce(xed1, 0) as noner,
	coalesce(alcohol,0) as alcohol, coalesce(drug,0) as drug, coalesce(injury,0) as injury, coalesce(psych,0) as psych,
	case when xacs.dx is null then 1 else 0 end as unc
from icd92005 n
left join recode 
on (n.dx = recode.original and startswith=0)
or (n.dx like recode.original || '%' and startswith=1)
left join xacs on recode.target = xacs.dx
left join (
	select dx,
		case when 'alcohol' = any(c) then 1 else 0 end as alcohol,
		case when 'drug' = any(c) then 1 else 0 end as drug,
		case when 'injury' = any(c) then 1 else 0 end as injury,
		case when 'psych' = any(c) then 1 else 0 end as psych
	from (
		select dx, array_agg(category) as c
		from special
		where category != 'ACS'
		group by 1
	) x
) special on recode.target like  special.dx || '%'
; -- Query returned successfully: 13367 rows affected, 1.5 secs execution time.
alter table nyued_original add constraint nyued_original_pkey primary key (dx);

drop table if exists nyued_2009;
create table nyued_2009 as
select data->>'Discharge DX' as dx, 
data->>'Dx Name' as dxname,
data->>'Dx Short Name' as dxshort,
(data->>'ED Care Needed, not Preventable/Avoidable')::numeric as edcnnpa,
(data->>'ED Care Needed, Preventable/Avoidable')::numeric as edcnpa,
(data->>'Emergent, PC Treatable')::numeric as epct,
(data->>'Non-Emergent')::numeric as noner,
(data->>'Alcohol')::numeric as alcohol,
(data->>'Drug')::numeric as drug,
(data->>'Injury')::numeric as injury,
(data->>'Psych')::numeric as psych,
(data->>'Unclassified')::numeric as unc
from stage.data_named_v
where id=4
; -- Query returned successfully: 14315 rows affected, 590 msec execution time.
alter table nyued_2009 add constraint nyued_2009_pkey primary key (dx);

drop table if exists nyued_2015;
create table nyued_2015 as
select data->>'discharge_dx' as dx, 
data->>'Dx_Name' as dxname,
data->>'Dx_Short_Name' as dxshort,
(data->>'ED_Care_Needed__not_Preventable_')::numeric as edcnnpa,
(data->>'ED_Care_Needed__Preventable_Avoi')::numeric as edcnpa,
(data->>'Emergent__PC_Treatable')::numeric as epct,
(data->>'Non_Emergent')::numeric as noner,
(data->>'Alcohol')::numeric as alcohol,
(data->>'Drug')::numeric as drug,
(data->>'Injury')::numeric as injury,
(data->>'Psych')::numeric as psych,
(data->>'Unclassified')::numeric as unc
-- ,(data->>'post2009')::numeric as post2009
from stage.data_named_v
where id=3
; -- Query returned successfully: 14613 rows affected, 946 msec execution time.
alter table nyued_2015 add constraint nyued_2015_pkey primary key (dx);

drop table if exists hesr_2017;
create table hesr_2017 as
select dx, null::text as dxname, null::text as dxshort,
xed4 as edcnnpa, xed3 as edcnpa, xed2 as epct, xed1 as noner, alcohol, drug, injury, psych, 0::integer as unc
from hesr
;
alter table hesr_2017 add constraint hesr_2017_pkey primary key (dx);


drop table if exists nyued_icd10_2015;
create table nyued_icd10_2015 as
select data->>'icd10cm' as dx, 
data->>'desc_long' as dxname,
data->>'desc_short' as dxshort,
(data->>'ED_Care_Needed__not_Preventable_')::numeric as edcnnpa,
(data->>'ED_Care_Needed__Preventable_Avoi')::numeric as edcnpa,
(data->>'Emergent__PC_Treatable')::numeric as epct,
(data->>'Non_Emergent')::numeric as noner,
(data->>'Alcohol')::numeric as alcohol,
(data->>'Drug')::numeric as drug,
(data->>'Injury')::numeric as injury,
(data->>'Psych')::numeric as psych,
(data->>'Unclassified')::numeric as unc
-- ,(data->>'post2009')::numeric as post2009
from stage.data_named_v
where id=5
; -- Query returned successfully: 14613 rows affected, 946 msec execution time.
alter table nyued_icd10_2015 add constraint nyued_icd10_2015_pkey primary key (dx);

drop table if exists hesr_icd10_2017;
create table hesr_icd10_2017 as
select dx, null::text as dxname, null::text as dxshort,
edcnnpa, edcnpa, epct, noner, alcohol, drug, injury, psych, 0::integer as unc
from hesr_icd10
;
alter table hesr_icd10_2017 add constraint hesr_icd10_2017_pkey primary key (dx);


\copy (select * from nyued_original order by 1) to 2000_icd9_nyu_original.csv csv header
\copy (select * from nyued_2009 order by 1) to 2009_icd9_nyu_update.csv csv header
\copy (select * from nyued_2015 order by 1) to 2015_icd9_nyu_update.csv csv header
\copy (select * from hesr_2017 order by 1) to 2017_icd9_hesr.csv csv header
\copy (select * from nyued_icd10_2015 order by 1) to 2015_icd10_nyu.csv csv header
\copy (select * from hesr_icd10_2017 order by 1) to 2017_icd10_hesr.csv csv header

select count(*) from nyued_original; -- 13367
select count(*) from nyued_2009; -- 14314
select count(*) from nyued_2015; -- 14613
select count(*) from hesr_2017; -- 7443
select count(*) from nyued_icd10_2015; -- 69823
select count(*) from hesr_icd10_2017; -- 47132


-- Compare Original NYUED 2000 revision with NYUED 2009 revision:
select 
	sum(case when w.dx is null then 1 else 0 end) as deleted,
	sum(case when o.dx is null then 1 else 0 end) as added,
	sum(case when o.dx is null and w.unc = 1 then 1 else 0 end) as added_uncategorized,
	sum(case when o.dx is null and w.unc = 0 then 1 else 0 end) as added_mapped,
	sum(case when o.dx is null and w.unc = 0 and w.injury=1 then 1 else 0 end) as added_mapped_injury,
	sum(case when o.dx is null and w.unc = 0 and w.psych=1 then 1 else 0 end) as added_mapped_psych,
	sum(case when o.dx is null and w.unc = 0 and (w.noner + w.epct + w.edcnpa + w.edcnnpa) > 0 then 1 else 0 end) as added_mapped_ermap,
	sum(case when o.unc = 0 and w.unc = 1 then 1 else 0 end) as cat2uncat,
	sum(case when o.unc = 1 and w.unc = 0 then 1 else 0 end) as uncat2cat,
	sum(case when (
		round(w.noner,10) != round(o.noner,10)
		or round(w.epct,10) != round(o.epct,10)
		or round(w.edcnpa,10) != round(o.edcnpa,10)
		or round(w.edcnnpa,10) != round(o.edcnnpa,10)
		) and o.unc = 0 and w.unc = 0
		then 1 else 0 end) as ed_score_change,
	sum(case when (
		round(w.noner,10) != round(o.noner,10)
		or round(w.epct,10) != round(o.epct,10)
		or round(w.edcnpa,10) != round(o.edcnpa,10)
		or round(w.edcnnpa,10) != round(o.edcnnpa,10)
		) and o.unc = 0 and w.unc = 0 
			and (o.noner + o.epct + o.edcnpa + o.edcnnpa) !=0
			and (w.noner + w.epct + w.edcnpa + w.edcnnpa) = 0
		then 1 else 0 end) as remove_er_scoring,
	sum(case when (
		w.alcohol != o.alcohol
		or w.drug != o.drug
		or w.injury != o.injury
		or w.psych != o.psych
		) and o.unc = 0 and w.unc = 0
		then 1 else 0 end) as special_score_change,
	sum(w.edcnnpa), sum(w.edcnpa), sum(w.epct), sum(w.noner), sum(w.alcohol), sum(w.drug), sum(w.injury), sum(w.psych), sum(w.unc)
-- select *
from nyued_original o
full outer join nyued_2009 w on w.dx = o.dx
;


-- Compare NYUED 2009 revision with NYUED 2015 revision:
select
	sum(case when w.dx is null then 1 else 0 end) as deleted,
	sum(case when o.dx is null then 1 else 0 end) as added,
	sum(case when o.dx is null and w.unc = 1 then 1 else 0 end) as added_uncategorized,
	sum(case when o.dx is null and w.unc = 0 then 1 else 0 end) as added_uncat,
	sum(case when o.dx is null and w.unc = 0 and w.injury=1 then 1 else 0 end) as added_mapped_injury,
	sum(case when o.dx is null and w.unc = 0 and w.psych=1 then 1 else 0 end) as added_mapped_psych,
	sum(case when w.unc not in (1, 0) then 1 else 0 end) as fractional_unc,
	sum(case when o.dx is null and w.unc = 0 and (w.noner + w.epct + w.edcnpa + w.edcnnpa) > 0 then 1 else 0 end) as added_mapped_ermap,
	sum(case when o.unc = 0 and w.unc = 1 then 1 else 0 end) as cat2uncat,
	sum(case when o.unc = 1 and w.unc = 0 then 1 else 0 end) as uncat2cat,
	sum(case when (
		round(w.noner,10) != round(o.noner,10)
		or round(w.epct,10) != round(o.epct,10)
		or round(w.edcnpa,10) != round(o.edcnpa,10)
		or round(w.edcnnpa,10) != round(o.edcnnpa,10)
		) and o.unc = 0 and w.unc = 0
		then 1 else 0 end) as ed_score_change,
	sum(case when (
		round(w.noner,10) != round(o.noner,10)
		or round(w.epct,10) != round(o.epct,10)
		or round(w.edcnpa,10) != round(o.edcnpa,10)
		or round(w.edcnnpa,10) != round(o.edcnnpa,10)
		) and o.unc = 0 and w.unc = 0 
			and (o.noner + o.epct + o.edcnpa + o.edcnnpa) !=0
			and (w.noner + w.epct + w.edcnpa + w.edcnnpa) = 0
		then 1 else 0 end) as remove_er_scoring,
	sum(case when (
		w.alcohol != o.alcohol
		or w.drug != o.drug
		or w.injury != o.injury
		or w.psych != o.psych
		) and o.unc = 0 and w.unc = 0
		then 1 else 0 end) as special_score_change,
	sum(w.edcnnpa), sum(w.edcnpa), sum(w.epct), sum(w.noner), sum(w.alcohol), sum(w.drug), sum(w.injury), sum(w.psych), sum(w.unc)
from nyued_2009 o
full outer join nyued_2015 w on w.dx = o.dx
;


-- Compare NYUED 2009 revision with HESR "Patch":
select
	sum(case when w.dx is null then 1 else 0 end) as deleted,
	sum(case when o.dx is null then 1 else 0 end) as added,
	sum(case when o.dx is null and w.unc = 1 then 1 else 0 end) as added_uncategorized,
	sum(case when o.dx is null and w.unc = 0 then 1 else 0 end) as added_uncat,
	sum(case when o.dx is null and w.unc = 0 and w.injury=1 then 1 else 0 end) as added_mapped_injury,
	sum(case when o.dx is null and w.unc = 0 and w.psych=1 then 1 else 0 end) as added_mapped_psych,
	sum(case when o.dx is null and w.unc = 0 and (w.noner + w.epct + w.edcnpa + w.edcnnpa) > 0 then 1 else 0 end) as added_mapped_ermap,
	sum(case when o.unc = 0 and w.unc = 1 then 1 else 0 end) as cat2uncat,
	sum(case when o.unc = 1 and w.unc = 0 then 1 else 0 end) as uncat2cat,
	sum(case when (
		round(w.noner,10) != round(o.noner,10)
		or round(w.epct,10) != round(o.epct,10)
		or round(w.edcnpa,10) != round(o.edcnpa,10)
		or round(w.edcnnpa,10) != round(o.edcnnpa,10)
		) and o.unc = 0 and w.unc = 0
		then 1 else 0 end) as ed_score_change,
	sum(case when (
		round(w.noner,10) != round(o.noner,10)
		or round(w.epct,10) != round(o.epct,10)
		or round(w.edcnpa,10) != round(o.edcnpa,10)
		or round(w.edcnnpa,10) != round(o.edcnnpa,10)
		) and o.unc = 0 and w.unc = 0 
			and (o.noner + o.epct + o.edcnpa + o.edcnnpa) !=0
			and (w.noner + w.epct + w.edcnpa + w.edcnnpa) = 0
		then 1 else 0 end) as remove_er_scoring,
	sum(case when (
		w.alcohol != o.alcohol
		or w.drug != o.drug
		or w.injury != o.injury
		or w.psych != o.psych
		) and o.unc = 0 and w.unc = 0
		then 1 else 0 end) as special_score_change,
	sum(w.edcnnpa), sum(w.edcnpa), sum(w.epct), sum(w.noner), sum(w.alcohol), sum(w.drug), sum(w.injury), sum(w.psych), sum(w.unc)
from nyued_2009 o
full outer join hesr_2017 w on w.dx = o.dx
;



-- Compare NYUED 2015 ICD10 version with HESR "Patch":
select
	sum(case when w.dx is null then 1 else 0 end) as deleted,
	sum(case when w.dx is null and o.unc=1 then 1 else 0 end) as deleted_unclassified,
	sum(case when w.dx is null and o.unc!=1 then 1 else 0 end) as deleted_classified,
	sum(case when o.dx is null then 1 else 0 end) as added,
	sum(case when o.dx is null and w.unc = 1 then 1 else 0 end) as added_uncategorized,
	sum(case when o.dx is null and w.unc = 0 then 1 else 0 end) as added_uncat,
	sum(case when o.dx is null and w.unc = 0 and w.injury=1 then 1 else 0 end) as added_mapped_injury,
	sum(case when o.dx is null and w.unc = 0 and w.psych=1 then 1 else 0 end) as added_mapped_psych,
	sum(case when o.dx is null and w.unc = 0 and (w.noner + w.epct + w.edcnpa + w.edcnnpa) > 0 then 1 else 0 end) as added_mapped_ermap,
	sum(case when o.unc not in (1,0) then 1 else 0 end) as fractional_unclassified,
	sum(case when o.unc = 0 and w.unc = 1 then 1 else 0 end) as cat2uncat,
	sum(case when o.unc = 1 and w.unc = 0 then 1 else 0 end) as uncat2cat,
	sum(case when (
		round(w.noner,10) != round(o.noner,10)
		or round(w.epct,10) != round(o.epct,10)
		or round(w.edcnpa,10) != round(o.edcnpa,10)
		or round(w.edcnnpa,10) != round(o.edcnnpa,10)
		) and o.unc != 1 and w.unc != 1
		then 1 else 0 end) as ed_score_change,
	sum(case when (
		round(w.noner,10) != round(o.noner,10)
		or round(w.epct,10) != round(o.epct,10)
		or round(w.edcnpa,10) != round(o.edcnpa,10)
		or round(w.edcnnpa,10) != round(o.edcnnpa,10)
		) and o.unc != 1 and w.unc != 1
			and (o.noner + o.epct + o.edcnpa + o.edcnnpa) !=0
			and (w.noner + w.epct + w.edcnpa + w.edcnnpa) = 0
		then 1 else 0 end) as remove_er_scoring,
	sum(case when (
		w.alcohol != o.alcohol
		or w.drug != o.drug
		or w.injury != o.injury
		or w.psych != o.psych
		) and o.unc != 1 and w.unc != 1
		then 1 else 0 end) as special_score_change,
	sum(w.edcnnpa), sum(w.edcnpa), sum(w.epct), sum(w.noner), sum(w.alcohol), sum(w.drug), sum(w.injury), sum(w.psych), sum(w.unc)
from nyued_icd10_2015 o
full outer join hesr_icd10_2017 w on w.dx = o.dx
;


