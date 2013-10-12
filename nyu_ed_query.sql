select c.*
	, case when drug=1 or alcohol=1	then 1 else 0 end as drugalc
	, ed1 + ed2 + ed3 as ed123
from (
	select b.*
		, case when special=1 or xed1 is null then 0 else xed1 end as ed1
		, case when special=1 or xed2 is null then 0 else xed2 end as ed2
		, case when special=1 or xed3 is null then 0 else xed3 end as ed3
		, case when special=1 or xed4 is null then 0 else xed4 end as ed4
		, case when special=1 or dx is not null then 0 else 1 end as unclassified
		, case when special=1 then 0 else coalesce(xed1,0) end as ne
		, case when special=1 then 0 else coalesce(xed2,0) end as pecpct
		, case when special=1 then 0 when     acs=1 then coalesce(xed3 + xed4, 0) else 0 end as edcnpa
		, case when special=1 then 0 when not acs=1 then coalesce(xed3 + xed4, 0) else 0 end as edcnnpa
	from (
		select a.*, x.*, x.dx as prindx, recode as groupeddx
			, case when injury.dx  is null then 0 else 1 end as injury
			, case when psych.dx   is null then 0 else 1 end as psych
			, case when alcohol.dx is null then 0 else 1 end as alcohol
			, case when drug.dx    is null then 0 else 1 end as drug
			, case when special.dx is null then 0 else 1 end as special
			, case when acs.dx     is null then 0 else 1 end as acs
		from (
			select s.*, case when trim(icd9) in ('7891','7893','78930') then trim(icd9)
				else coalesce(target, trim(icd9)) end as recode
--=======>>> INPUT TABLE HERE (with diagnosis code name of "icd9".  All other fields, optional, but will be carried to output)
			from (select icd9, dob, age, gender from my_source_data) s
			left join recode on icd9 like original || case when startswith=1 then '%' else '' end
				and substr(icd9,1,3) = substr(original,1,3) -- redundant, but helps with performance
		) a
		left join xacs x on recode=dx
		left join (select dx from special where category ='injury')   injury on recode like  injury.dx || '%'
			and substr(recode,1,1) = substr(injury.dx,1,1)  -- redundant, but helps with performance
		left join (select dx from special where category ='psych')     psych on recode like   psych.dx || '%'
			and substr(recode,1,1) = substr(psych.dx,1,1)   -- redundant, but helps with performance
		left join (select dx from special where category ='alcohol') alcohol on recode like alcohol.dx || '%'
			and substr(recode,1,1) = substr(alcohol.dx,1,1) -- redundant, but helps with performance
		left join (select dx from special where category ='drug')       drug on recode like    drug.dx || '%'
			and substr(recode,1,1) = substr(drug.dx,1,1)    -- redundant, but helps with performance
		left join (select dx from special where category in ('injury','psych','alcohol','drug')) special on recode like special.dx || '%'
			and substr(recode,1,1) = substr(special.dx,1,1) -- redundant, but helps with performance
		left join (select dx from special where category='ACS')          acs on recode like     acs.dx || '%'
			and substr(recode,1,1) = substr(acs.dx,1,1)     -- redundant, but helps with performance
	) b
) c
;