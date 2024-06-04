USE [CalibreSSiSdev]
GO

/****** Object:  StoredProcedure [emula].[OM_BusPack_Emulation_Version_BI]    Script Date: 4/06/2024 5:48:05 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO








CREATE procedure [emula].[OM_BusPack_Emulation_Version_BI] 
( @version varchar(99)
 , @suffix varchar(99)) AS
BEGIN
											----------------------------------------------
											--				INITIALISATION				--
											----------------------------------------------

DECLARE
-- Step 1: All Base Rating Factors
  @BI_Emulation_Step1 NVARCHAR(MAX)

-- Step 2: Calculate Rating Factor Relativities
, @BI_Emulation_Step2 NVARCHAR(MAX)

-- Step 3: Calculate Premium
, @BI_Emulation_Step3_A NVARCHAR(MAX)
, @BI_Emulation_Step3_B NVARCHAR(MAX)
, @BI_Emulation_Step3_C NVARCHAR(MAX)


										----------------------------------------------------------
										--	EMULATION PROCESS: RUNS ALL STEPS FOR EMULATION
										----------------------------------------------------------

------------------------------------
-- Base Table: Attach Rating Factors
------------------------------------

SET @BI_Emulation_Step1='

drop table if exists  CalibreSSiSdev.emula.OM_BI_testing_input_'+@suffix+'_'+@version+';

select
	a.policy_number
	, a.policy_id
	, a.address_id
	, a.modified_date
	, a.TERM_START_DATE
	, a.TERM_END_DATE
	, a.stage_code
	, a.Channel
	, a.Category
	, a.state
	, a.ANZSIC
	, a.SUBURB
	, a.PCODE
	, a.LocationType
	, a.Tenant1_Occ
	, a.Tenant2_Occ
	, a.Tenant3_Occ
	, a.Tenant4_Occ
	, a.Tenant5_Occ
	, a.Tenant6_Occ
	, a.Tenant7_Occ
	, iif(a.tenant_count is null, 0, a.tenant_count) as tenant_count
	, a.PROPERTY_SECTION_TAKEN + a.BI_SECTION_TAKEN  + a.LIABILITY_SECTION_TAKEN 
		+ a.EMPLOYEE_SECTION_TAKEN + a.GLASS_SECTION_TAKEN + a.GENERAL_PROPERTY_SECTION_TAKEN +
		MACHINERY_SECTION_TAKEN + a.MONEY_SECTION_TAKEN + THEFT_SECTION_TAKEN +
		a.TAX_SECTION_TAKEN + a.TRANSIT_SECTION_TAKEN + a.ELECTRIONIC_SECTION_TAKEN as total_section
	, a.BI_IndemnityPeriod
	, a.BI_COVER_TYPE
	, a.BI_SI
	, a.LossOfRent
	, a.aicow
	, a.claimspreparation
	, a.documents
	, a.[AdditionalDocuments]
	, a.goodwill
	, a.accountsreceivable
	, a.Dependency_1
	, a.Dependency_2
	, a.claimLoading
	, a.CLLoading
	, a.CL01Loding_prpOnly
	, a.DDLoading
	, a.PNLoading
	, a.SSLoading
into CalibreSSiSdev.emula.OM_BI_testing_input_'+@suffix+'_'+@version+'
from CalibreSSiSdev.emula.testing_input_'+@suffix+' a 
	where BI_SECTION_TAKEN = 1 
;'
;

------------------------------------
-- Attach Required Relativities
------------------------------------

SET @BI_Emulation_Step2='
drop table if exists  CalibreSSiSdev.emula.OM_bi_pre_1_'+@suffix+'_'+@version+';

with temp as (
select
	a.*
	, case when a.Tenant1_Occ != '''' then b1.bi_rel else ''0'' end as Tenant1_Occ_bi_rel
	, case when a.Tenant2_Occ != '''' then b2.bi_rel else ''0'' end as Tenant2_Occ_bi_rel
	, case when a.Tenant3_Occ != '''' then b3.bi_rel else ''0'' end as Tenant3_Occ_bi_rel
	, case when a.Tenant4_Occ != '''' then b4.bi_rel else ''0'' end as Tenant4_Occ_bi_rel
	, case when a.Tenant5_Occ != '''' then b5.bi_rel else ''0'' end as Tenant5_Occ_bi_rel
	, case when a.Tenant6_Occ != '''' then b6.bi_rel else ''0'' end as Tenant6_Occ_bi_rel
	, case when a.Tenant7_Occ != '''' then b7.bi_rel else ''0'' end as Tenant7_Occ_bi_rel
	, b8.bi_rel as ANZSIC_bi_rel
from CalibreSSiSdev.emula.OM_BI_testing_input_'+@suffix+'_'+@version+' a 
	left join CalibreSSiSdev.dbo.ccomm_occupation_'+@suffix+'_'+@version+' b1 --updated
		on a.Tenant1_Occ = b1.calliden_code  collate SQL_Latin1_General_CP1_CI_AS 
		and b1.CURRENT_FLAG = ''YES''

	left join CalibreSSiSdev.dbo.ccomm_occupation_'+@suffix+'_'+@version+' b2 --updated
		on a.Tenant2_Occ = b2.calliden_code collate SQL_Latin1_General_CP1_CI_AS 
		and b2.CURRENT_FLAG = ''YES''

	left join CalibreSSiSdev.dbo.ccomm_occupation_'+@suffix+'_'+@version+' b3 --updated
		on a.Tenant3_Occ = b3.calliden_code collate SQL_Latin1_General_CP1_CI_AS 
		and b3.CURRENT_FLAG = ''YES'' 

	left join CalibreSSiSdev.dbo.ccomm_occupation_'+@suffix+'_'+@version+' b4 --updated
		on a.Tenant4_Occ = b4.calliden_code collate SQL_Latin1_General_CP1_CI_AS 
		and b4.CURRENT_FLAG = ''YES'' 

	left join CalibreSSiSdev.dbo.ccomm_occupation_'+@suffix+'_'+@version+' b5 --updated
		on a.Tenant5_Occ = b5.calliden_code collate SQL_Latin1_General_CP1_CI_AS 
	and b5.CURRENT_FLAG = ''YES'' 

	left join CalibreSSiSdev.dbo.ccomm_occupation_'+@suffix+'_'+@version+' b6 --updated
		on a.Tenant6_Occ = b6.calliden_code collate SQL_Latin1_General_CP1_CI_AS 
		and b6.CURRENT_FLAG = ''YES''

	left join CalibreSSiSdev.dbo.ccomm_occupation_'+@suffix+'_'+@version+' b7 --updated
		on a.Tenant7_Occ = b7.calliden_code collate SQL_Latin1_General_CP1_CI_AS 
		and b7.CURRENT_FLAG = ''YES'' 


	left join CalibreSSiSdev.dbo.ccomm_occupation_'+@suffix+'_'+@version+' b8 --updated
		on a.ANZSIC = b8.calliden_code  collate SQL_Latin1_General_CP1_CI_AS 
		and b8.CURRENT_FLAG = ''YES'' 
)

select 
	a.*
	, case when a.Category=''PO'' then 
		(select max(max_rel) from (values (Tenant1_Occ_bi_rel),(Tenant2_Occ_bi_rel),(Tenant3_Occ_bi_rel),(Tenant4_Occ_bi_rel),(Tenant5_Occ_bi_rel),(Tenant6_Occ_bi_rel),(Tenant7_Occ_bi_rel))
			b(max_rel)   -- If PO, Use the tenents with highest risk
	) 
	else a.ANZSIC_bi_rel end as BI_Occupation_Rel
	, case when b.fireClassification = ''Low Hazard / Medium Hazard'' 
		then coalesce(cast(c1.value as numeric(15,5)),1) * coalesce(cast(d1.value as numeric(15,5)),1)
		else coalesce(cast(c2.value as numeric(15,5)),1) * coalesce(cast(d2.value as numeric(15,5)),1) end as BI_Specified_Customers_Suppliers_Rel
	, b.birel as BI_Suburb_Rel
	, 1 as Scheme_Rel
into CalibreSSiSdev.emula.OM_bi_pre_1_'+@suffix+'_'+@version+'
From temp a 
	left join CalibreSSiSdev.dbo.ccomm_location_'+@suffix+'_'+@version+' b --updated
		on a.STATE + ''_'' + a.SUBURB + ''_'' + a.PCODE = b.locationindex collate SQL_Latin1_General_CP1_CI_AS
	outer apply CalibreSSiSdev.dbo.emula_SDP_BUSINESSPROPERTY_LOWER_UPPER_core_'+@suffix+'_'+@version+'(''BICustomerSuppliers'',''Low Hazard / Medium Hazard'','''','''',
			cast(case when a.Dependency_1 = '''' then ''-1'' else a.Dependency_1 end  as numeric(15,5))) c1 
	outer apply CalibreSSiSdev.dbo.emula_SDP_BUSINESSPROPERTY_LOWER_UPPER_core_'+@suffix+'_'+@version+'(''Alpine, Bushfire, Cyclone, Island, Remote'',''Low Hazard / Medium Hazard'','''','''',
			cast(case when a.Dependency_1 = '''' then ''-1'' else a.Dependency_1 end as numeric(15,5))) c2 
	outer apply CalibreSSiSdev.dbo.emula_SDP_BUSINESSPROPERTY_LOWER_UPPER_core_'+@suffix+'_'+@version+'(''BICustomerSuppliers'',''Low Hazard / Medium Hazard'','''','''',
			cast(case when a.Dependency_2 = '''' then ''-1'' else a.Dependency_2 end  as numeric(15,5))) d1 
	outer apply CalibreSSiSdev.dbo.emula_SDP_BUSINESSPROPERTY_LOWER_UPPER_core_'+@suffix+'_'+@version+'(''Alpine, Bushfire, Cyclone, Island, Remote'',''Low Hazard / Medium Hazard'','''','''',
			cast(case when a.Dependency_2 = '''' then ''-1'' else a.Dependency_2 end as numeric(15,5))) d2 
	where b.CURRENT_FLAG = ''YES''
;'
;
-------------------------------------Calculate the Prem ---------------------------------

SET @BI_Emulation_Step3_A='
drop table if exists  CalibreSSiSdev.emula.OM_bi_premium_'+@suffix+'_'+@version+';

with temp as (
select
	a.*
	, b.Weighted_Avg_Rate_for_PD  --(1)

	, c.relativityvalue as Indemnity_rel
	, coalesce(b.Weighted_Avg_Rate_for_PD,1) * 
		coalesce(BI_Occupation_Rel,1) * coalesce(BI_Suburb_Rel,1) * 
		coalesce(BI_Specified_Customers_Suppliers_Rel,1)  as Base_Rate_for_Annual_Revenue  -- (2)

	, coalesce(b.Weighted_Avg_Rate_for_PD,1) * 
		coalesce(BI_Occupation_Rel,1) * coalesce(BI_Suburb_Rel,1)  as Base_Rate_for_Loss_of_Rent_Receivable --(3)

	, coalesce(b.Weighted_Avg_Rate_for_PD,1) * coalesce(c.relativityvalue,1) *
		coalesce(BI_Occupation_Rel,1)  as Base_Rate_for_Others  -- (4)

from CalibreSSiSdev.emula.OM_bi_pre_1_'+@suffix+'_'+@version+' a 
	left join CalibreSSiSdev.emula.OM_property_premium_'+@suffix+'_'+@version+' b
		on a.policy_id = b.policy_id and a.address_id = b.address_id
	left join CalibreSSiSdev.dbo.ccomm_bi_'+@suffix+'_'+@version+' c
		on a.bi_indemnityperiod = c.code collate SQL_Latin1_General_CP1_CI_AS 
		and a.BI_COVER_TYPE = c.relativitytype collate SQL_Latin1_General_CP1_CI_AS
		and c.CURRENT_FLAG = ''YES''
where Weighted_Avg_Rate_for_PD is not null
),   --- GET the base rates
temp2 as (
select 
	a.*
	, case when a.BI_COVER_TYPE = ''GROSSPROF'' then  
		coalesce(a.Base_Rate_for_Annual_Revenue * b1.relativityvalue  * a.BI_SI * coalesce(Scheme_Rel,1),0)
		else 0 end as Premium_for_Insurance_Gross_Profit  -- (5)
	, case when a.BI_COVER_TYPE = ''WEEKREV'' then  
		coalesce(a.Base_Rate_for_Annual_Revenue * b2.relativityvalue  * a.BI_SI * coalesce(Scheme_Rel,1),0)  
		else 0 end as Premium_for_Weekly_Revenue    --(6)
	, case when a.BI_COVER_TYPE = ''ANNREV'' then  
		coalesce(a.Base_Rate_for_Annual_Revenue * b3.relativityvalue  * a.BI_SI * coalesce(Scheme_Rel,1),0)
		else 0 end as Premium_for_Annual_Revenue   --(7)
	, case when a.BI_COVER_TYPE = ''WEEKREV'' then 
			coalesce( a.Base_Rate_for_Loss_of_Rent_Receivable * a.LossOfRent * c.relativityvalue,0)
		when a.BI_COVER_TYPE != ''WEEKREV'' and a.BI_COVER_TYPE = ''AICOWONLY'' then 0
		when a.BI_COVER_TYPE != ''WEEKREV'' and a.BI_COVER_TYPE != ''AICOWONLY'' then
			coalesce(a.Base_Rate_for_Loss_of_Rent_Receivable * a.LossOfRent * c.relativityvalue,0)
		else 0
		end as Premuim_for_Loss_of_Rent_Receivable   --(8)

';

SET @BI_Emulation_Step3_B='

	, case when (a.aicow = 0 or a.aicow is null) then ''0''
		when a.aicow  > 0 and a.BI_COVER_TYPE != ''AICOWONLY'' and (bi_si is null or bi_si = 0)
		then coalesce(a.Base_Rate_for_Others * d.relativityvalue *
		(select max(AICOW) from 
		(values (a.AICOW - e1.value),(0)) as b(AICOW)),0)  --(9.1)
		when a.aicow  > 0 and a.BI_COVER_TYPE != ''AICOWONLY'' and bi_si > 0 
		then coalesce(a.Base_Rate_for_Others * 
		(select max(AICOW) from 
		(values (a.AICOW - e1.value),(0)) as b(AICOW)) ,0)  --(9.2)
		when a.AICOW > 0 and a.BI_COVER_TYPE = ''AICOWONLY'' and (bi_si is null or bi_si = 0)
		then coalesce(a.Base_Rate_for_Others * d.relativityvalue * a.AICOW,0)  --(9.1)
		when a.AICOW > 0 and a.BI_COVER_TYPE = ''AICOWONLY'' and bi_si > 0 
		then coalesce(a.Base_Rate_for_Others * a.AICOW,0)   --(9.2)
		end as Premium_for_AICOW   --(9)
	, coalesce(a.Base_Rate_for_Others * 
		(select max(claimspreparation) from 
		(values (a.ClaimsPreparation - e2.value),(0)) as b(claimspreparation))
		,0) as Premium_for_Claim_Preparation   --(10)

	, case when a.Documents > 0 and a.BI_COVER_TYPE = ''WEEKREV'' then
		 a.Base_Rate_for_Others * 
		(select max(documents_freecover) from
		(values (0),
		(a.documents - 0.2 * ( coalesce(a.LossOfRent,0) * b2.relativityvalue + --coalesce(a.Documents,0) * b2.relativityvalue + --2022 removed
			coalesce(a.BI_SI,0) + coalesce(a.AICOW,0) + coalesce(a.accountsreceivable,0) + coalesce(a.ClaimsPreparation,0)))
		 ) as b(documents_freecover))
		 when a.Documents > 0 and a.BI_COVER_TYPE != ''WEEKREV'' then 
		 a.Base_Rate_for_Others * 
		(select max(documents_freecover) from
		(values (0),
		(a.documents - 0.2 * (coalesce(a.LossOfRent,0) + --coalesce(a.Documents,0) + --2022 removed
			coalesce(a.BI_SI,0) + coalesce(a.AICOW,0) + coalesce(a.accountsreceivable,0) + coalesce(a.ClaimsPreparation,0)))
		 ) as b(documents_freecover))
		 else 0 end as Premium_for_Documents   --(11)
	, coalesce(a.Base_Rate_for_Others * a.goodwill,0) as Premium_for_Goodwill  --(12)
	, coalesce(a.Base_Rate_for_Others * 
		 (select max(accountsreceivable) from 
		 (values (a.accountsreceivable - e3.value),(0)) as b(accountsreceivable)) 
		 ,0) as Premium_for_Accounts_Receivable   --(13)


';

SET @BI_Emulation_Step3_C='

from temp a 
	left join CalibreSSiSdev.dbo.ccomm_bi_'+@suffix+'_'+@version+' b1
		on a.bi_indemnityperiod = b1.code collate SQL_Latin1_General_CP1_CI_AS
		and b1.relativitytype = ''GROSSPROF'' and b1.CURRENT_FLAG = ''YES''
	left join CalibreSSiSdev.dbo.ccomm_bi_'+@suffix+'_'+@version+' b2
		on a.bi_indemnityperiod = b2.code collate SQL_Latin1_General_CP1_CI_AS
		and b2.relativitytype = ''WEEKREV'' and b2.CURRENT_FLAG = ''YES''
	left join CalibreSSiSdev.dbo.ccomm_bi_'+@suffix+'_'+@version+' b3
		on a.bi_indemnityperiod = b3.code collate SQL_Latin1_General_CP1_CI_AS
		and b3.relativitytype = ''ANNREV'' and b3.CURRENT_FLAG = ''YES''
	left join CalibreSSiSdev.dbo.ccomm_bi_'+@suffix+'_'+@version+' c
		on substring(a.BI_IndemnityPeriod,1,3) = c.code collate SQL_Latin1_General_CP1_CI_AS
		and c.relativitytype = ''LOSSOFRENT'' and c.CURRENT_FLAG = ''YES''
	left join CalibreSSiSdev.dbo.ccomm_bi_'+@suffix+'_'+@version+' d
		on a.BI_IndemnityPeriod = d.code collate SQL_Latin1_General_CP1_CI_AS
		and d.relativitytype = ''AICOWONLY''and d.CURRENT_FLAG = ''YES''
	left join CalibreSSiSdev.dbo.ccomm_freecovers_'+@suffix+'_'+@version+' e1
		on e1.section = ''BusinessInterruption'' and e1.covertype = ''AICOW'' and e1.CURRENT_FLAG = ''YES'' 
	left join CalibreSSiSdev.dbo.ccomm_freecovers_'+@suffix+'_'+@version+' e2
		on e2.section = ''BusinessInterruption'' and e2.covertype = ''Claims Preparation'' and e2.CURRENT_FLAG = ''YES'' 
	left join CalibreSSiSdev.dbo.ccomm_freecovers_'+@suffix+'_'+@version+' e3
		on e3.section = ''BusinessInterruption'' and e3.covertype = ''Accounts Receivable'' and e3.CURRENT_FLAG = ''YES''
)
select distinct 
	a.*
	, b.value as BI_minPrem
	, (select max(max_premium) from (values
		((a.Premium_for_Insurance_Gross_Profit + a.Premium_for_Weekly_Revenue + a.Premium_for_Annual_Revenue
			+ a.Premuim_for_Loss_of_Rent_Receivable + a.Premium_for_AICOW + a.Premium_for_Claim_Preparation 
			+ a.Premium_for_Documents + a.Premium_for_Goodwill + a.Premium_for_Accounts_Receivable * c.multisectiondiscount)
			), (b.value)) c(max_premium)
		) * a.claimLoading* a.CLLoading* a.CL01Loding_prpOnly * a.DDLoading  * a.SSLoading* a.PNLoading--added by Karen 2022
		as Total_BI_Premium
into CalibreSSiSdev.emula.OM_bi_premium_'+@suffix+'_'+@version+'
from temp2 a 
	left join CalibreSSiSdev.dbo.ccomm_minimum_'+@suffix+'_'+@version+' b
		on b.section = ''BusinessInterruption'' and type = ''Minimum_Premium'' and CURRENT_FLAG = ''YES''
	left join CalibreSSiSdev.emula.OM_property_premium_'+@suffix+'_'+@version+' c
		on a.policy_id = c.policy_id and a.address_id = c.address_id;
;';
EXEC(@BI_Emulation_Step1 + @BI_Emulation_Step2 + @BI_Emulation_Step3_A + @BI_Emulation_Step3_B + @BI_Emulation_Step3_C);


END
GO


