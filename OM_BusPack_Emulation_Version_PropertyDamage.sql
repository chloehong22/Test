USE [CalibreSSiSdev]
GO

/****** Object:  StoredProcedure [emula].[OM_BusPack_Emulation_Version_PropertyDamage_Test]    Script Date: 4/06/2024 5:52:13 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE procedure [emula].[OM_BusPack_Emulation_Version_PropertyDamage_Test] 
( @version varchar(99)
  , @suffix varchar(99)) AS
BEGIN
											----------------------------------------------
											--				INITIALISATION				--
											----------------------------------------------

DECLARE
-- Step 1: All Base Rating Factors
  @PD_Emulation_Step1 NVARCHAR(MAX)

-- Step 2: Calculate Base Rate
, @PD_Emulation_Step2 NVARCHAR(MAX)

-- Step 3: Rating Factor Relativities: Occupation, Suburb, Construction, Building Age, Locality, Total SI, Excess, PO Rel
, @PD_Emulation_Step3_A NVARCHAR(MAX)
, @PD_Emulation_Step3_B NVARCHAR(MAX)

-- Step 4: Fire Protection Relativities
, @PD_Emulation_Step4_A NVARCHAR(MAX)
, @PD_Emulation_Step4_B NVARCHAR(MAX)
, @PD_Emulation_Step4_C NVARCHAR(MAX)
, @PD_Emulation_Step4_D NVARCHAR(MAX)

-- Step 5: Fire Protection Relativities
, @PD_Emulation_Step5 NVARCHAR(MAX)

-- Step 6: Fire Protection Relativities
, @PD_Emulation_Step6 NVARCHAR(MAX)

-- Step 7: Fire Protection Relativities
, @PD_Emulation_Step7_A NVARCHAR(MAX)
, @PD_Emulation_Step7_B NVARCHAR(MAX)
, @PD_Emulation_Step7_C NVARCHAR(MAX)
, @PD_Emulation_Step7_D NVARCHAR(MAX)
, @PD_Emulation_Step7_E NVARCHAR(MAX)

-- Step 8: Fire Protection Relativities
, @PD_Emulation_Step8_A NVARCHAR(MAX)
, @PD_Emulation_Step8_B NVARCHAR(MAX)

-- Step 9: Fire Protection Relativities
, @PD_Emulation_Step9 NVARCHAR(MAX)

-- Step 10: Fire Protection Relativities
, @PD_Emulation_Step10_A NVARCHAR(MAX)
, @PD_Emulation_Step10_B NVARCHAR(MAX)

;


										----------------------------------------------------------
										--	EMULATION PROCESS: RUNS ALL STEPS FOR EMULATION
										----------------------------------------------------------

------------------------------------
-- Base Table: Attach Rating Factors
------------------------------------

SET @PD_Emulation_Step1='

drop table if exists  CalibreSSiSdev.emula.OM_Fire_testing_input1_'+@suffix+'_'+@version+';
with temp as (
select 
	a.* 
	, b1.[value] as FC_AICOW 
	, b2.[value] as FC_AccountsReceivable
	, b3.[value] as FC_claimsPreparation
	, (a.BI_SI + a.AICOW + a.AccountsReceivable + a.claimsPreparation + a.lossofRent) as BI_SI_for_documents
	, (a.BI_SI + a.AICOW + a.AccountsReceivable + a.claimsPreparation + a.lossofRent) * 0.2 as FC_documents
from CalibreSSiSdev.emula.testing_input_'+@suffix+' a
	left join CalibreSSiSdev.dbo.ccomm_freecovers_final b1 --Karen add 2022
	on a.policy_number is not null and b1.section = ''BusinessInterruption'' and b1.CURRENT_FLAG = ''yes'' and b1.covertype = ''AICOW'' 
	left join CalibreSSiSdev.dbo.ccomm_freecovers_final b2 --Karen add 2022
	on a.policy_number is not null and b2.section = ''BusinessInterruption'' and b2.CURRENT_FLAG = ''yes'' and b2.covertype = ''Accounts Receivable''
	left join CalibreSSiSdev.dbo.ccomm_freecovers_final b3 --Karen add 2022
	on a.policy_number is not null and b3.section = ''BusinessInterruption'' and b3.CURRENT_FLAG = ''yes'' and b3.covertype = ''Claims Preparation''
where PROPERTY_SECTION_TAKEN = 1 
)
select
	a.policy_number
	, a.policy_id
	, a.address_id
	, a.modified_date
	, a.TERM_START_DATE
	, a.TERM_END_DATE
	, a.STAGE_CODE
	, a.status_code
	, a.Channel
	, a.PROPERTY_SECTION_TAKEN

	, a.BI_COVER_TYPE
	, a.BI_IndemnityPeriod
	, a.BI_IndemnityPeriodWks
	, a.Category
	, a.state
	, a.ANZSIC
	, a.SUBURB
	, a.PCODE
	, a.Tenant1_Occ
	, a.Tenant2_Occ
	, a.Tenant3_Occ
	, a.Tenant4_Occ
	, a.Tenant5_Occ
	, a.Tenant6_Occ
	, a.Tenant7_Occ
	, a.Policy_situation_count
	, iif(a.tenant_count is null, 0, a.tenant_count) as tenant_count

	, a.WallConstruction
	, a.RoofConstruction
	, a.FloorConstruction
	, a.YearBuilt
	, a.LocationType
	, a.BuildingSumInsured
	, a.ContentsSumInsured
	, a.StockSumInsured
	, a.SpecifiedItemsSumInsured
	, a.RewritingRecordsSumInsured
	, a.DebrisSumInsured
	, a.ExtraCostSumInsured
	, a.PlayingSurfacesSumInsured

	, a.[OverrideDescription], a.PropertyPrintableNotes
	, a.claimLoading, a.CLLoading, a.CL01Loding_prpOnly, a.DDLoading, a.PNLoading, a.SSLoading, a.floodloading
	, a.claimLoading* a.CLLoading* a.CL01Loding_prpOnly* a.DDLoading* a.PNLoading* a.SSLoading* a.floodloading as loading_aggr


	, a.BI_SI
	, a.AICOW
	, iif(a.AICOW - FC_AICOW > 0, a.AICOW - FC_AICOW, 0) as AICOW_over_FC
	, a.AccountsReceivable
	, iif(a.AccountsReceivable - FC_AccountsReceivable > 0, a.AccountsReceivable - FC_AccountsReceivable, 0) as AccountsReceivable_over_FC
	, a.claimsPreparation
	, iif(a.claimsPreparation -FC_claimsPreparation> 0, a.claimsPreparation - FC_claimsPreparation, 0) as claimsPreparation_over_FC
	, a.lossofRent
	, a.documents
	, iif(a.documents - FC_documents > 0, a.documents - FC_documents, 0) as documents_over_FC
	, a.goodwill


	, coalesce(BuildingSumInsured,0) + coalesce(ContentsSumInsured,0) + coalesce(StockSumInsured,0)+ coalesce(SpecifiedItemsSumInsured,0) 
		as TotalFireSI
	, a.LimitOfliability
	, coalesce(a.PropertyExcess,0) as PropertyExcess

	, a.Fire_Protection_0
	, a.Fire_Protection_1
	, a.Fire_Protection_2
	, a.Fire_Protection_3
	, a.Fire_Protection_4
	, a.Fire_Protection_5
	, a.Fire_Protection_6
	, a.Fire_Protection_7
	, a.Fire_Protection_8
	, a.Fire_Protection_9
	, a.Fire_Protection_10
	, a.Fire_Protection_11
	, case when Fire_Protection_1 = ''EXTING''  and Fire_Protection_2 = ''REELS'' then 1 else 0 end as EXISTING_REEL
	, case when (Fire_Protection_1 is NULL and 
			  Fire_Protection_2 is NULL and
			  Fire_Protection_3 is NULL and
			  Fire_Protection_4 is NULL and
			  Fire_Protection_5 is NULL and
			  Fire_Protection_6 is NULL and
			  Fire_Protection_7 is NULL and
			  Fire_Protection_8 is NULL and
			  Fire_Protection_9 is NULL and
			  Fire_Protection_10 is NULL and
			  Fire_Protection_11 is NULL
			  ) then 0 else 1 end as Fire_Protection_1_to_11
	, a.PercentSprinklerCoverage
	, a.SprinklerStandards
	, a.SprinklerWaterType
	, a.AtmOnPremises
	, a.FireBrigade
	, a.MonitoredBaseAlarmType
	, a.FlammableGoodsQuantity
	, a.HasFlammableGoods

	, a.Security_Protection_0
	, a.Security_Protection_1
	, a.Security_Protection_2
	, a.Security_Protection_3
	, a.Security_Protection_4
	, a.Security_Protection_5
	, a.Security_Protection_6
	, a.Security_Protection_7
	, a.Security_Protection_8
	, a.Security_Protection_9
	, a.Security_Protection_10
	, a.Security_Protection_11
	, a.Security_Protection_12
	, a.Security_Protection_13
	, case when (a.Security_Protection_1 is null and 
			   a.Security_Protection_2 is null and
			   a.Security_Protection_3 is null and
			   a.Security_Protection_4 is null and
			   a.Security_Protection_5 is null and
			   a.Security_Protection_6 is null and
			   a.Security_Protection_7 is null and
			   a.Security_Protection_8 is null and
			   a.Security_Protection_9 is null and
			   a.Security_Protection_10 is null and
			   a.Security_Protection_11 is null and
			   a.Security_Protection_12 is null and
			   a.Security_Protection_13 is null)  then 0 else 1 end as Security_Protection_1_to_13
		   
	, a.ConnectedTownWater
	, a.HasMultipleBuildings
	, a.EpsAmount
	, a.NumberOfStories
	, a.IsHeritageListed
	, a.StrataMortgageeInterestOnly
	, a.YearRewired
	, a.WasteRemovalStorage
	, a.SprayPainting
	, a.DeepFryers
	, a.DeepFryersOilVolume
	, a.DeepFryersCapacity
	, a.DeepFryersExhaustSystem
	, a.PlasticsMoulding
	, a.DeepFryersThermostat
	, a.PropertyDustExtractorFitted
	, a.UnattendedEquipmentOperation
	, a.StorageHeight
	, a.PropertyDustExtractorCleaned
	,	a.PROPERTY_SECTION_TAKEN + a.BI_SECTION_TAKEN  + a.LIABILITY_SECTION_TAKEN 
		+ a.EMPLOYEE_SECTION_TAKEN + a.GLASS_SECTION_TAKEN + a.GENERAL_PROPERTY_SECTION_TAKEN +
		MACHINERY_SECTION_TAKEN + a.MONEY_SECTION_TAKEN + THEFT_SECTION_TAKEN +
		a.TAX_SECTION_TAKEN + a.TRANSIT_SECTION_TAKEN + a.ELECTRIONIC_SECTION_TAKEN as total_section

	, year(TERM_START_DATE) - cast(YearBuilt as float) as building_age
	, year(TERM_START_DATE) - a.YearRewired as RewiredAge

	, a.ManufacturingPercentage 
	, a.WashFacility
	, a.FibreGlassWork
	, a.StorageWarehouse
	, a.RepairServicePremises
	, a.RestaurantorBar
	, a.Woodworking
	, a.WoodworkingDustExtractorCleaning
	, a.WoodworkingDustExtractors
	, a.SprayPaintingControl
	, a.WasteRemovalProcess
	, a.TimberStorageYard
	, a.Fire_Class

	, a.OSQ107_Count
	, a.OSQ100_Count
	, a.OSQ104_Count
	, a.OSQ99_Count
	, a.OSQ111_Count
	, a.OSQ112A_Count
	, a.OSQ112B_Count

into CalibreSSiSdev.emula.OM_Fire_testing_input1_'+@suffix+'_'+@version+' 
from temp a
;

---------------------------------
--	Attach Situation Count
---------------------------------

drop table if exists  CalibreSSiSdev.emula.OM_Fire_testing_input_'+@suffix+'_'+@version+'

select 
	a.*
	, b.situation_count
into CalibreSSiSdev.emula.OM_Fire_testing_input_'+@suffix+'_'+@version+'
from CalibreSSiSdev.emula.OM_Fire_testing_input1_'+@suffix+'_'+@version+' a
	left join
	(
	select policy_number,  count(*) as situation_count
	from CalibreSSiSdev.emula.OM_Fire_testing_input1_'+@suffix+'_'+@version+'
	group by policy_number
	) b
on a.policy_number = b.policy_number
;'
;


-----------------------------------------------------------------------
-- Building & Contents, Natural Peril Base Rate,   Based on SI -  (30 secs)
------------------------------------------------------------------------

SET @PD_Emulation_Step2='
drop table if exists  CalibreSSiSdev.emula.OM_building_natural_peril_'+@suffix+'_'+@version+';
with temp1 as (
select a.*,
	-- FIRE SUM INSURED
	case 
	when a.BI_COVER_TYPE = ''AICOWONLY'' or a.BI_COVER_TYPE is null then --updated in 2022
	CAST(coalesce(BuildingSumInsured,0) + coalesce(ContentsSumInsured,0) + coalesce(StockSumInsured,0)+coalesce(SpecifiedItemsSumInsured,0)
	+ coalesce(BI_SI,0) + coalesce(AICOW,0) + coalesce(AccountsReceivable_over_FC,0) + coalesce(claimsPreparation_over_FC,0) + coalesce(lossofRent,0) 
	+ coalesce(documents_over_FC,0) + coalesce(goodwill,0) AS numeric(18,2))

	when a.BI_COVER_TYPE != ''WEEKREV'' or a.BI_COVER_TYPE is null then
	CAST(coalesce(BuildingSumInsured,0) + coalesce(ContentsSumInsured,0) + coalesce(StockSumInsured,0)+coalesce(SpecifiedItemsSumInsured,0)
	+ coalesce(BI_SI,0) + coalesce(AICOW_over_FC,0) + coalesce(AccountsReceivable_over_FC,0) + coalesce(claimsPreparation_over_FC,0) + coalesce(lossofRent,0) 
	+ coalesce(documents_over_FC,0) + coalesce(goodwill,0) AS numeric(18,2))

	else 
	CAST(coalesce(BuildingSumInsured,0) + coalesce(ContentsSumInsured,0) + coalesce(StockSumInsured,0) + coalesce(SpecifiedItemsSumInsured,0)
	+ coalesce(BI_SI,0) * b.loadingvalue + coalesce(AICOW_over_FC,0) + coalesce(AccountsReceivable_over_FC,0) + coalesce(claimsPreparation_over_FC,0) + coalesce(lossofRent,0) * b.loadingvalue 
	+ coalesce(documents_over_FC,0) + coalesce(goodwill,0) AS numeric(18,2))
	end as Total_SI   -- get the total SI
	 from CalibreSSiSdev.emula.OM_Fire_testing_input_'+@suffix+'_'+@version+' a 
		 left join CalibreSSiSdev.dbo.ccomm_bi_final b --updated
		 on a.BI_COVER_TYPE = b.relativitytype collate SQL_Latin1_General_CP1_CI_AS
		 and Coalesce(a.BI_IndemnityPeriod collate SQL_Latin1_General_CP1_CI_AS, a.BI_IndemnityPeriodWks collate SQL_Latin1_General_CP1_CI_AS) = b.code collate SQL_Latin1_General_CP1_CI_AS and CURRENT_FLAG = ''YES''
),

temp2 as (
-- BASE RATE: BLDG/CONT and PERIL
select 
	a.*
	, d.suminsuredfrom as sum_insured_base
	, cast(d.premiumlow as numeric(15,8)) as bldg_cont_prem_low
	, d.newrate as bldg_cont_new_rate
	, cast(d2.premiumlow as numeric(15,8)) as peril_prem_low
	, d2.newrate as peril_new_rate 
from temp1 a 
left join CalibreSSiSdev.dbo.ccomm_businessproperty_sicurve_final d --updated
	on a.STATE = d.state collate SQL_Latin1_General_CP1_CI_AS and d.type = ''Bldg_Cont'' 
	and cast(a.Total_SI as numeric) >= cast(d.suminsuredfrom as numeric) 
	and cast(a.Total_SI as numeric) <= cast(d.suminsuredto as numeric) 
	and d.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_sicurve_final d2 --updated
	on a.STATE = d2.state collate SQL_Latin1_General_CP1_CI_AS and d2.type = ''Peril'' 
	and cast(a.Total_SI as numeric) >= cast(d2.suminsuredfrom as numeric)
	and cast(a.Total_SI as numeric) <= cast(d2.suminsuredto as numeric) 
	and d2.CURRENT_FLAG = ''YES''
)

select 
	a.*
	, case when Total_SI > 0 then 
		cast((( a.Total_SI - a.sum_insured_base ) * bldg_cont_new_rate + bldg_cont_prem_low) / Total_SI as numeric(15,8) ) 
		else NULL end as Building_Contents_Base_Rate        -- (1.1)
	, case when Total_SI > 0 then 
		cast((( a.Total_SI - a.sum_insured_base ) * peril_new_rate + peril_prem_low) / Total_SI as numeric(15,8) ) 
		else NULL end as peril_Base_Rate          -- (1.2)
into CalibreSSiSdev.emula.OM_building_natural_peril_'+@suffix+'_'+@version+'
from temp2 a
;'
;

------------------------------------------------------------------------------
---Occ, Suburb, Construction, Building Age, Locality, Total SI, Excess, PO Rel - (10 mins)
------------------------------------------------------------------------------

SET @PD_Emulation_Step3_A='

drop table if exists  CalibreSSiSdev.emula.OM_property_pre_1_'+@suffix+'_'+@version+'

select 
	a.* 
	, case when a.Category = ''Non_PO'' then 0
		   when a.Category = ''PO'' then 
				(select max(bld_occ_rel_tenent_max) from (values (coalesce(b1.fire_bldg_rel,0)), (coalesce(b2.fire_bldg_rel,0)),(coalesce(b3.fire_bldg_rel,0)),
					(coalesce(b4.fire_bldg_rel,0)), (coalesce(b5.fire_bldg_rel,0)),(coalesce(b6.fire_bldg_rel,0)),(coalesce(b7.fire_bldg_rel,0))
					) as c(bld_occ_rel_tenent_max))
		end as bld_occ_rel_tenent_max

	, coalesce(b1.fire_bldg_rel,0) as Tenant_1_Occ_rel
	, coalesce(b2.fire_bldg_rel,0) as Tenant_2_Occ_rel
	, coalesce(b3.fire_bldg_rel,0) as Tenant_3_Occ_rel
	, coalesce(b4.fire_bldg_rel,0) as Tenant_4_Occ_rel
	, coalesce(b5.fire_bldg_rel,0) as Tenant_5_Occ_rel
	, coalesce(b6.fire_bldg_rel,0) as Tenant_6_Occ_rel
	, coalesce(b7.fire_bldg_rel,0) as Tenant_7_Occ_rel

	, case when a.Category = ''Non_PO'' then bb.fire_bldg_rel
		when a.Category = ''PO'' and coalesce(b1.fire_bldg_rel,0) + coalesce(b2.fire_bldg_rel,0) + coalesce(b3.fire_bldg_rel,0) + coalesce(b4.fire_bldg_rel,0) + coalesce(b5.fire_bldg_rel,0) + coalesce(b6.fire_bldg_rel,0)+ coalesce(b7.fire_bldg_rel,0)= 0 then 1
		when a.Category = ''PO'' and coalesce(b1.fire_bldg_rel,0) + coalesce(b2.fire_bldg_rel,0) + coalesce(b3.fire_bldg_rel,0) + coalesce(b4.fire_bldg_rel,0) + coalesce(b5.fire_bldg_rel,0)  + coalesce(b6.fire_bldg_rel,0)+ coalesce(b7.fire_bldg_rel,0)> 0
		then 
			(select max(bld_occ_rel_tenent_max) from (values (coalesce(b1.fire_bldg_rel,0)), (coalesce(b2.fire_bldg_rel,0)),(coalesce(b3.fire_bldg_rel,0)),
			(coalesce(b4.fire_bldg_rel,0)), (coalesce(b5.fire_bldg_rel,0)),(coalesce(b6.fire_bldg_rel,0)),(coalesce(b7.fire_bldg_rel,0))
			) as c(bld_occ_rel_tenent_max))
			 end as Occupation_Building_Rel

	, case when a.Category = ''Non_PO'' then bb.fire_cso_rel
		when a.Category = ''PO'' and 
		coalesce(b1.fire_cso_rel,0) + coalesce(b2.fire_cso_rel,0) + coalesce(b3.fire_cso_rel,0)
			+ coalesce(b4.fire_cso_rel,0) + coalesce(b5.fire_cso_rel,0)+ coalesce(b6.fire_cso_rel,0)+ coalesce(b7.fire_cso_rel,0) = 0
		 then 1
		when a.Category = ''PO'' and 
		coalesce(b1.fire_cso_rel,0) + coalesce(b2.fire_cso_rel,0) + coalesce(b3.fire_cso_rel,0)
			+ coalesce(b4.fire_cso_rel,0) + coalesce(b5.fire_cso_rel,0)+ coalesce(b6.fire_cso_rel,0)+ coalesce(b7.fire_cso_rel,0) > 0
		then 
			(select max(cso_occ_rel_tenent_max) from (values (coalesce(b1.fire_cso_rel,0)), (coalesce(b2.fire_cso_rel,0)),(coalesce(b3.fire_cso_rel,0)),
			(coalesce(b4.fire_cso_rel,0)), (coalesce(b5.fire_cso_rel,0)),(coalesce(b6.fire_cso_rel,0)),(coalesce(b7.fire_cso_rel,0))
			) as c(cso_occ_rel_tenent_max))
			end as Occupation_CSO_Rel
	 , c1.FireBldgRel as Suburb_Building_Rel
	 , c1.FireCSORel as Suburb_CSO_Rel
	 , c1.FirePerilsRel as Suburb_Peril_Rel
	 , cast(d1.value as numeric(15,8)) as Wall_Building_Rel
	 , cast(d2.value as numeric(15,8)) as Wall_CSO_Rel
	 , cast(d3.value as numeric(15,8)) as Wall_Peril_Rel
	 , cast(e1.value as numeric(15,8)) as Roof_Building_Rel
	 , cast(e2.value as numeric(15,8)) as Roof_CSO_Rel
	 , cast(e3.value as numeric(15,8)) as Roof_Peril_Rel
	 , cast(f1.value as numeric(15,8)) as Floor_Building_Rel
	 , cast(f2.value as numeric(15,8)) as Floor_CSO_Rel
	 , cast(f3.value as numeric(15,8)) as Floor_Peril_Rel
	 , cast(g1.value as numeric(15,8)) as Building_Age_Building_Rel
	 , cast(g2.value as numeric(15,8)) as Building_Age_CSO_Rel
	 , cast(g3.value as numeric(15,8)) as Building_Age_Peril_Rel
	 , coalesce(cast(h1.value as numeric(15,8)),0) as Locality_Building_Rel
	 , coalesce(cast(h2.value as numeric(15,8)),0) as Locality_CSO_Rel
	 , cast(h3.value as numeric(15,8)) as Locality_Peril_Rel
	 , cast(i1.value as numeric(15,8)) as Total_SI_Building_Rel
	 , cast(i2.value as numeric(15,8)) as Total_SI_CSO_Rel
	 , cast(i3.value as numeric(15,8)) as Total_SI_Peril_Rel
	 , cast(j1.relativity as numeric(15,8)) as Excess_Building_Rel
	 , cast(j2.relativity as numeric(15,8)) as Excess_CSO_Rel
	 , cast(j3.relativity as numeric(15,8)) as Excess_Peril_Rel
	 , cast(k1.value as numeric(15,8)) as PO_Building_Rel
	 , cast(k2.value as numeric(15,8)) as PO_CSO_Rel
	 , cast(k3.value as numeric(15,8)) as PO_Peril_Rel
 
into CalibreSSiSdev.emula.OM_property_pre_1_'+@suffix+'_'+@version+'
from CalibreSSiSdev.emula.OM_building_natural_peril_'+@suffix+'_'+@version+' a 
left join CalibreSSiSdev.dbo.ccomm_occupation_final b1 --updated
	on  a.Tenant1_Occ = cast(b1.calliden_code as varchar) collate SQL_Latin1_General_CP1_CI_AS
	and b1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_occupation_final b2 --updated
	on a.Tenant2_Occ = cast(b2.calliden_code as varchar) collate SQL_Latin1_General_CP1_CI_AS
	and b2.CURRENT_FLAG = ''YES'' 
left join CalibreSSiSdev.dbo.ccomm_occupation_final b3 --updated
	on a.Tenant3_Occ = cast(b3.calliden_code as varchar) collate SQL_Latin1_General_CP1_CI_AS
	and b3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_occupation_final b4 --updated
	on a.Tenant4_Occ = cast(b4.calliden_code as varchar) collate SQL_Latin1_General_CP1_CI_AS
	and b4.CURRENT_FLAG = ''YES'' 
left join CalibreSSiSdev.dbo.ccomm_occupation_final b5 --updated
	on a.Tenant5_Occ = cast(b5.calliden_code as varchar) collate SQL_Latin1_General_CP1_CI_AS
	and b5.CURRENT_FLAG = ''YES''  
left join CalibreSSiSdev.dbo.ccomm_occupation_final b6 --updated
	on a.Tenant6_Occ = cast(b6.calliden_code as varchar) collate SQL_Latin1_General_CP1_CI_AS
	and b6.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_occupation_final b7 --updated
	on a.Tenant7_Occ = cast(b7.calliden_code as varchar) collate SQL_Latin1_General_CP1_CI_AS
	and b7.CURRENT_FLAG = ''YES'' 
left join CalibreSSiSdev.dbo.ccomm_occupation_final bb --updated
	on a.ANZSIC = cast(bb.calliden_code as varchar) collate SQL_Latin1_General_CP1_CI_AS 
	and bb.CURRENT_FLAG = ''YES'' 

left join CalibreSSiSdev.dbo.ccomm_location_final c1 --updated
	on a.state + ''_'' + upper(a.suburb) + ''_'' + a.pcode = c1.locationindex collate SQL_Latin1_General_CP1_CI_AS
	and c1.CURRENT_FLAG = ''YES'' 

';


SET @PD_Emulation_Step3_B='
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final d1
	on a.WallConstruction = d1.code collate SQL_Latin1_General_CP1_CI_AS
	and d1.relativitytype = ''Building'' and d1.groupid = ''WALL'' 
	and d1.CURRENT_FLAG = ''YES'' 
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final d2
	on a.WallConstruction = d2.code collate SQL_Latin1_General_CP1_CI_AS
	and d2.relativitytype = ''CSO'' and d2.groupid = ''WALL''
	and d2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final d3
	on a.WallConstruction = d3.code collate SQL_Latin1_General_CP1_CI_AS
	and d3.relativitytype = ''Peril'' and d3.groupid = ''WALL''
	and d3.CURRENT_FLAG = ''YES'' 

left join CalibreSSiSdev.dbo.ccomm_businessproperty_final e1
	on a.RoofConstruction = e1.code collate SQL_Latin1_General_CP1_CI_AS
	and e1.relativitytype = ''Building'' and e1.groupid = ''Roof''
	and e1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final e2
	on a.RoofConstruction = e2.code collate SQL_Latin1_General_CP1_CI_AS
	and e2.relativitytype = ''CSO'' and e2.groupid = ''Roof''
	and e2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final e3
	on a.RoofConstruction = e3.code collate SQL_Latin1_General_CP1_CI_AS
	and e3.relativitytype = ''Peril'' and e3.groupid = ''Roof''
	and e3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final f1
	on a.FloorConstruction = f1.code collate SQL_Latin1_General_CP1_CI_AS
	and f1.relativitytype = ''Building'' and f1.groupid = ''Floor''
	and f1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final f2
	on a.FloorConstruction = f2.code collate SQL_Latin1_General_CP1_CI_AS
	and f2.relativitytype = ''CSO'' and f2.groupid = ''Floor''
	and f2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final f3
	on a.FloorConstruction = f3.code collate SQL_Latin1_General_CP1_CI_AS
	and f3.relativitytype = ''Peril'' and f3.groupid = ''Floor''
	and f3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final g1
	on a.building_age >= g1.lowerfrom and 
	a.building_age <= g1.upperto 
	and g1.groupid = ''BuildingAge'' and g1.relativitytype = ''Building''
	and g1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final g2
	on a.building_age >= g2.lowerfrom and 
	a.building_age <= g2.upperto 
	and g2.groupid = ''BuildingAge'' and g2.relativitytype = ''CSO''
	and g2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final g3
	on a.building_age >= g3.lowerfrom and 
	a.building_age <= g3.upperto 
	and g3.groupid = ''BuildingAge'' and g3.relativitytype = ''Peril''
	and g3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final h1
	on a.LocationType = h1.code collate SQL_Latin1_General_CP1_CI_AS
	and h1.relativitytype = ''Building'' and h1.groupid  = ''FireLocationType''
	and h1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final h2
	on a.LocationType = h2.code collate SQL_Latin1_General_CP1_CI_AS
	and h2.relativitytype = ''CSO'' and h2.groupid  = ''FireLocationType''
	and h2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final h3
	on a.LocationType = h3.code collate SQL_Latin1_General_CP1_CI_AS
	and h3.relativitytype = ''Peril'' and h3.groupid  = ''FireLocationType''
	and h3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final i1
	on a.Total_SI >= cast(i1.lowerfrom as float) and 
	a.Total_SI < cast(i1.upperto as float)
	and i1.groupid = ''TotalFireSI'' and i1.relativitytype = ''Building''
	and i1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final i2
	on a.Total_SI >= cast(i2.lowerfrom as float) and 
	a.Total_SI < cast(i2.upperto as float)
	and i2.groupid = ''TotalFireSI'' and i2.relativitytype = ''CSO''
	and i2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final i3
	on a.Total_SI >= cast(i3.lowerfrom as float) and 
	a.Total_SI < cast(i3.upperto as float)
	and i3.groupid = ''TotalFireSI'' and i3.relativitytype = ''Peril''
	and i3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_excess_final j1
	on j1.relativitytype = ''Fire_BuildingExcess'' and a.STATE = j1.state collate SQL_Latin1_General_CP1_CI_AS
	and a.PropertyExcess = j1.excessvalue
	and j1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_excess_final j2
	on j2.relativitytype = ''Fire_CSOExcess'' and a.STATE = j2.state collate SQL_Latin1_General_CP1_CI_AS
	and a.PropertyExcess = j2.excessvalue
	and j2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_excess_final j3
	on j3.relativitytype = ''Fire_PerilsExcess'' and a.STATE = j3.state collate SQL_Latin1_General_CP1_CI_AS
	and a.PropertyExcess = j3.excessvalue
	and j3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final k1
	on k1.groupid = ''PropertyOwner'' and 
	case when a.Category=''PO'' then ''Yes'' else ''NO'' end = k1.code
	and k1.relativitytype = ''Building''
	and k1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final k2
	on k2.groupid = ''PropertyOwner'' and 
	case when a.Category=''PO'' then ''Yes'' else ''NO'' end = k2.code
	and k2.relativitytype = ''CSO''
	and k2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final k3
	on k3.groupid = ''PropertyOwner'' and 
	case when a.Category=''PO'' then ''Yes'' else ''NO'' end = k3.code
	and k3.relativitytype = ''Peril''
	and k3.CURRENT_FLAG = ''YES''
where a.WallConstruction is not null 
;'
;


------------------------------------------------------------------------------
--- Fire Protection Relativities
------------------------------------------------------------------------------
SET @PD_Emulation_Step4_A='
drop table if exists  CalibreSSiSdev.emula.OM_property_pre_2_temp_'+@suffix+'_'+@version+'

select 
	a.*
	, coalesce(cast(l1.value as numeric(15,8)),1) as FP1_Building_Rel
	, coalesce(cast(l2.value as numeric(15,8)),1) as FP1_CSO_Rel
	, coalesce(cast(l3.value as numeric(15,8)),1) as FP1_Peril_Rel
	, coalesce(cast(m1.value as numeric(15,8)),1) as FP2_Building_Rel
	, coalesce(cast(m2.value as numeric(15,8)),1) as FP2_CSO_Rel
	, coalesce(cast(m3.value as numeric(15,8)),1) as FP2_Peril_Rel
	, coalesce(cast(n1.value as numeric(15,8)),1) as FP3_Building_Rel
	, coalesce(cast(n2.value as numeric(15,8)),1) as FP3_CSO_Rel
	, coalesce(cast(n3.value as numeric(15,8)),1) as FP3_Peril_Rel
	, coalesce(cast(ll1.value as numeric(15,8)),1) as FP4_Building_Rel
	, coalesce(cast(ll2.value as numeric(15,8)),1) as FP4_CSO_Rel
	, coalesce(cast(ll3.value as numeric(15,8)),1) as FP4_Peril_Rel
	, coalesce(cast(mm1.value as numeric(15,8)),1) as FP5_Building_Rel
	, coalesce(cast(mm2.value as numeric(15,8)),1) as FP5_CSO_Rel
	, coalesce(cast(mm3.value as numeric(15,8)),1) as FP5_Peril_Rel
	, coalesce(cast(nn1.value as numeric(15,8)),1) as FP6_Building_Rel
	, coalesce(cast(nn2.value as numeric(15,8)),1) as FP6_CSO_Rel
	, coalesce(cast(nn3.value as numeric(15,8)),1) as FP6_Peril_Rel
	, coalesce(cast(lll1.value as numeric(15,8)),1) as FP7_Building_Rel
	, coalesce(cast(lll2.value as numeric(15,8)),1) as FP7_CSO_Rel
	, coalesce(cast(lll3.value as numeric(15,8)),1) as FP7_Peril_Rel
	, coalesce(cast(mmm1.value as numeric(15,8)),1) as FP8_Building_Rel
	, coalesce(cast(mmm2.value as numeric(15,8)),1) as FP8_CSO_Rel
	, coalesce(cast(mmm3.value as numeric(15,8)),1) as FP8_Peril_Rel
	, coalesce(cast(nnn1.value as numeric(15,8)),1) as FP9_Building_Rel
	, coalesce(cast(nnn2.value as numeric(15,8)),1) as FP9_CSO_Rel
	, coalesce(cast(nnn3.value as numeric(15,8)),1) as FP9_Peril_Rel
	, coalesce(cast(llll1.value as numeric(15,8)),1) as FP10_Building_Rel
	, coalesce(cast(llll2.value as numeric(15,8)),1) as FP10_CSO_Rel
	, coalesce(cast(llll3.value as numeric(15,8)),1) as FP10_Peril_Rel
	, coalesce(cast(mmmm1.value as numeric(15,8)),1) as FP11_Building_Rel
	, coalesce(cast(mmmm2.value as numeric(15,8)),1) as FP11_CSO_Rel
	, coalesce(cast(mmmm3.value as numeric(15,8)),1) as FP11_Peril_Rel
	, case when a.EXISTING_REEL =1
			  then cast(o1.value as numeric(15,8))/cast(o2.value as numeric(15,8))/cast(o3.value as numeric(15,8)) else ''1'' end as EXTING_REELS_BUILDING
	, case when a.EXISTING_REEL =1
			  then cast(p1.value as numeric(15,8))/cast(p2.value as numeric(15,8))/cast(p3.value as numeric(15,8))  else ''1'' end as EXTING_REELS_CSO
	, case when a.EXISTING_REEL =1
			  then cast(q1.value as numeric(15,8))/cast(q2.value as numeric(15,8))/cast(q3.value as numeric(15,8)) else ''1'' end as EXTING_REELS_Peril
	, case when Fire_Protection_4 = ''SMOKEMON'' and Fire_Protection_5 = ''SMOKEUNMON'' then 1 else 0 end as SMOKEMON_SMOKEUNMON
	, case when Fire_Protection_7 = ''FIREALARM'' and Fire_Protection_8 = ''BASEALARM''  then 1 else 0 end as FIREALARM_BASEALARM
	, case when (Fire_Protection_4 = ''SMOKEMON'' and Fire_Protection_5 = ''SMOKEUNMON'' )
			  then cast(r1.value as numeric(15,8))/cast(r2.value as numeric(15,8))/cast(r3.value as numeric(15,8)) else ''1'' end as SMOKEMON_SMOKEUNMON_Building
	, case when (Fire_Protection_4 = ''SMOKEMON'' and Fire_Protection_5 = ''SMOKEUNMON'' )
			  then cast(s1.value as numeric(15,8))/cast(s2.value as numeric(15,8))/cast(s3.value as numeric(15,8)) else ''1'' end as SMOKEMON_SMOKEUNMON_CSO
	, case when (Fire_Protection_4 = ''SMOKEMON'' and  Fire_Protection_5 = ''SMOKEUNMON'' )
			  then cast(t1.value as numeric(15,8))/cast(t2.value as numeric(15,8))/cast(t3.value as numeric(15,8)) else ''1'' end as SMOKEMON_SMOKEUNMON_Peril
	, case when (Fire_Protection_7 = ''FIREALARM'' and Fire_Protection_8 = ''BASEALARM'' )
			  then cast(u1.value as numeric(15,8))/cast(u2.value as numeric(15,8))/cast(u3.value as numeric(15,8)) else ''1'' end as FIREALARM_BASEALARM_Building
	, case when (Fire_Protection_7 = ''FIREALARM'' and Fire_Protection_8 = ''BASEALARM'' )
			  then cast(v1.value as numeric(15,8))/cast(v2.value as numeric(15,8))/cast(v3.value as numeric(15,8)) else ''1'' end as FIREALARM_BASEALARM_CSO
	, case when (Fire_Protection_7 = ''FIREALARM'' and Fire_Protection_8 = ''BASEALARM'')
			  then cast(w1.value as numeric(15,8))/cast(w2.value as numeric(15,8))/cast(w3.value as numeric(15,8)) else ''1'' end as FIREALARM_BASEALARM_Peril
	, case when Fire_Protection_3 = ''SPRINK''  then x1.value 
		 when Fire_Protection_1_to_11 = 0 then x2.value --NONE 1.365
		 else x3.value end as Min_Rel_Max_Discount_Fire_1_Building --Minimum1 0.8
	, case when Fire_Protection_3 = ''SPRINK'' then y1.value
		 when Fire_Protection_1_to_11 = 0  then y2.value
		 else y3.value end as Min_Rel_Max_Discount_Fire_1_CSO
	, case when Fire_Protection_3 = ''SPRINK'' then z1.value
		 when Fire_Protection_1_to_11 = 0  then z2.value
		 else z3.value end as Min_Rel_Max_Discount_Fire_1_Peril
	, case when Fire_Protection_3 = ''SPRINK'' then ba1.value  
			  else ba2.value end as Min_Rel_Max_Discount_Fire_2_Building --Minimum1 0.8
	, case when Fire_Protection_3 = ''SPRINK'' then bb1.value
			  else bb2.value end as Min_Rel_Max_Discount_Fire_2_CSO
	, case when Fire_Protection_3 = ''SPRINK'' then bc1.value
			  else bc2.value end as Min_Rel_Max_Discount_Fire_2_Peril
	, case when Fire_Protection_1_to_11 = 0  then ''1''
		  when Fire_Protection_3 = ''SPRINK'' and PercentSprinklerCoverage = 100 and 
			   (SprinklerWaterType = ''DUAL01'' or SprinklerWaterType = ''SING01'')
				and SprinklerStandards = ''YES'' then ''1''
		  when Fire_Protection_1 = ''EXTING'' then ''1'' 
		  else  bd1.value end as EXTING_NONE_Building --1.15
	, case when Fire_Protection_1_to_11 = 0 then ''1''
		  when Fire_Protection_3 = ''SPRINK'' and PercentSprinklerCoverage = 100 and 
			   (SprinklerWaterType = ''DUAL01'' or SprinklerWaterType = ''SING01'')
				and SprinklerStandards = ''YES'' then ''1''
		  when Fire_Protection_1 = ''EXTING'' then ''1''
		  else  bd2.value end as EXTING_NONE_CSO  --1.15
	, case when Fire_Protection_1_to_11 = 0 then ''1''
		  when Fire_Protection_3 = ''SPRINK'' and PercentSprinklerCoverage = 100 and 
			   (SprinklerWaterType = ''DUAL01'' or SprinklerWaterType = ''SING01'')
				and SprinklerStandards = ''YES'' then ''1''
		  when Fire_Protection_1 = ''EXTING'' then ''1''
		  else  bd2.value end as EXTING_NONE_Peril  --1.15
	, case when Fire_Protection_1_to_11 = 0 then ''1''
		  when Fire_Protection_3 = ''SPRINK'' and PercentSprinklerCoverage = 100 and 
			   (SprinklerWaterType = ''DUAL01'' or SprinklerWaterType = ''SING01'')
				and SprinklerStandards = ''YES'' then ''1''
		  when Fire_Protection_2 = ''REELS'' then ''1''
		  else  be1.value end as REELS_NONE_Building --1.02
	, case when Fire_Protection_1_to_11 = 0 then ''1''
		  when Fire_Protection_3 = ''SPRINK'' and PercentSprinklerCoverage = 100 and 
			   (SprinklerWaterType = ''DUAL01'' or SprinklerWaterType = ''SING01'')
				and SprinklerStandards = ''YES'' then ''1''
		  when Fire_Protection_2 = ''REELS'' then ''1''
		  else  be2.value end as REELS_NONE_CSO --1.02
	, case when Fire_Protection_1_to_11 = 0 then ''1''
		  when Fire_Protection_3 = ''SPRINK'' and PercentSprinklerCoverage = 100 and 
			   (SprinklerWaterType = ''DUAL01'' or SprinklerWaterType = ''SING01'')
				and SprinklerStandards = ''YES'' then ''1''
		  when Fire_Protection_2 = ''REELS'' then ''1''
		  else  be3.value end as REELS_NONE_Peril --1.02
	, Coalesce(bf1.value, ''1'') as Sprinklers_Building --(y)100%sprinkle+(y)standardsprinkle->0.7; others 1.
	, Coalesce(bf2.value, ''1'') as Sprinklers_CSO--(y)100%sprinkle+(y)standardsprinkle->0.7; others 1. 
	, Coalesce(bf3.value, ''1'') as Sprinklers_Peril --all 1
';


SET @PD_Emulation_Step4_B='
into CalibreSSiSdev.emula.OM_property_pre_2_temp_'+@suffix+'_'+@version+'
from CalibreSSiSdev.emula.OM_property_pre_1_'+@suffix+'_'+@version+' a 
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final l1
	on a.Fire_Protection_1 = l1.code  collate SQL_Latin1_General_CP1_CI_AS
	and l1.relativitytype  = ''Building''
	and l1.groupid = ''FireProtectionDiscount''
	and l1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final l2
	on a.Fire_Protection_1 = l2.code  collate SQL_Latin1_General_CP1_CI_AS
	and l2.relativitytype  = ''CSO''
	and l2.groupid = ''FireProtectionDiscount''
	and l2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final l3
	on a.Fire_Protection_1 = l3.code  collate SQL_Latin1_General_CP1_CI_AS
	and l3.relativitytype  = ''Peril''
	and l3.groupid = ''FireProtectionDiscount''
	and l3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final m1
	on a.Fire_Protection_2 = m1.code  collate SQL_Latin1_General_CP1_CI_AS
	and m1.relativitytype  = ''Building''
	and m1.groupid = ''FireProtectionDiscount''
	and m1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final m2
	on a.Fire_Protection_2 = m2.code  collate SQL_Latin1_General_CP1_CI_AS
	and m2.relativitytype  = ''CSO''
	and m2.groupid = ''FireProtectionDiscount''
	and m2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final m3
	on a.Fire_Protection_2 = m3.code  collate SQL_Latin1_General_CP1_CI_AS
	and m3.relativitytype  = ''Peril''
	and m3.groupid = ''FireProtectionDiscount''
	and m3.CURRENT_FLAG = ''YES''

left join CalibreSSiSdev.dbo.ccomm_businessproperty_final n1
	on a.Fire_Protection_3 = n1.code  collate SQL_Latin1_General_CP1_CI_AS
	and n1.relativitytype  = ''Building''
	and n1.groupid = ''FireProtectionDiscount''
	and n1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final n2
	on a.Fire_Protection_3 = n2.code  collate SQL_Latin1_General_CP1_CI_AS
	and n2.relativitytype  = ''CSO''
	and n2.groupid = ''FireProtectionDiscount''
	and n2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final n3
	on a.Fire_Protection_3 = n3.code  collate SQL_Latin1_General_CP1_CI_AS
	and n3.relativitytype  = ''Peril''
	and n3.groupid = ''FireProtectionDiscount''
	and n3.CURRENT_FLAG = ''YES''

left join CalibreSSiSdev.dbo.ccomm_businessproperty_final ll1
	on a.Fire_Protection_4 = ll1.code  collate SQL_Latin1_General_CP1_CI_AS
	and ll1.relativitytype  = ''Building''
	and ll1.groupid = ''FireProtectionDiscount''
	and ll1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final ll2
	on a.Fire_Protection_4 = ll2.code  collate SQL_Latin1_General_CP1_CI_AS
	and ll2.relativitytype  = ''CSO''
	and ll2.groupid = ''FireProtectionDiscount''
	and ll2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final ll3
	on a.Fire_Protection_4 = ll3.code  collate SQL_Latin1_General_CP1_CI_AS
	and ll3.relativitytype  = ''Peril''
	and ll3.groupid = ''FireProtectionDiscount''
	and ll3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final mm1
	on a.Fire_Protection_5 = mm1.code  collate SQL_Latin1_General_CP1_CI_AS
	and mm1.relativitytype  = ''Building''
	and mm1.groupid = ''FireProtectionDiscount''
	and mm1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final mm2
	on a.Fire_Protection_5 = mm2.code  collate SQL_Latin1_General_CP1_CI_AS
	and mm2.relativitytype  = ''CSO''
	and mm2.groupid = ''FireProtectionDiscount''
	and mm2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final mm3
	on a.Fire_Protection_5 = mm3.code  collate SQL_Latin1_General_CP1_CI_AS
	and mm3.relativitytype  = ''Peril''
	and mm3.groupid = ''FireProtectionDiscount''
	and mm3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final nn1
	on a.Fire_Protection_6 = nn1.code  collate SQL_Latin1_General_CP1_CI_AS
	and nn1.relativitytype  = ''Building''
	and nn1.groupid = ''FireProtectionDiscount''
	and nn1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final nn2
	on a.Fire_Protection_6 = nn2.code  collate SQL_Latin1_General_CP1_CI_AS
	and nn2.relativitytype  = ''CSO''
	and nn2.groupid = ''FireProtectionDiscount''
	and nn2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final nn3
	on a.Fire_Protection_6 = nn3.code  collate SQL_Latin1_General_CP1_CI_AS
	and nn3.relativitytype  = ''Peril''
	and nn3.groupid = ''FireProtectionDiscount''
	and nn3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final lll1
	on a.Fire_Protection_7 = lll1.code  collate SQL_Latin1_General_CP1_CI_AS
	and lll1.relativitytype  = ''Building''
	and lll1.groupid = ''FireProtectionDiscount''
	and lll1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final lll2
	on a.Fire_Protection_7 = lll2.code  collate SQL_Latin1_General_CP1_CI_AS
	and lll2.relativitytype  = ''CSO''
	and lll2.groupid = ''FireProtectionDiscount''
	and lll2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final lll3
	on a.Fire_Protection_7 = lll3.code  collate SQL_Latin1_General_CP1_CI_AS
	and lll3.relativitytype  = ''Peril''
	and lll3.groupid = ''FireProtectionDiscount''
	and lll3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final mmm1
	on a.Fire_Protection_8 = mmm1.code  collate SQL_Latin1_General_CP1_CI_AS
	and mmm1.relativitytype  = ''Building''
	and mmm1.groupid = ''FireProtectionDiscount''
	and mmm1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final mmm2
	on a.Fire_Protection_8 = mmm2.code  collate SQL_Latin1_General_CP1_CI_AS
	and mmm2.relativitytype  = ''CSO''
	and mmm2.groupid = ''FireProtectionDiscount''
	and mmm2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final mmm3
	on a.Fire_Protection_8 = mmm3.code  collate SQL_Latin1_General_CP1_CI_AS
	and mmm3.relativitytype  = ''Peril''
	and mmm3.groupid = ''FireProtectionDiscount''
	and mmm3.CURRENT_FLAG = ''YES''
';



SET @PD_Emulation_Step4_C='
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final nnn1
	on a.Fire_Protection_9 = nnn1.code  collate SQL_Latin1_General_CP1_CI_AS
	and nnn1.relativitytype  = ''Building''
	and nnn1.groupid = ''FireProtectionDiscount''
	and nnn1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final nnn2
	on a.Fire_Protection_9 = nnn2.code  collate SQL_Latin1_General_CP1_CI_AS
	and nnn2.relativitytype  = ''CSO''
	and nnn2.groupid = ''FireProtectionDiscount''
	and nnn2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final nnn3
	on a.Fire_Protection_9 = nnn3.code  collate SQL_Latin1_General_CP1_CI_AS
	and nnn3.relativitytype  = ''Peril''
	and nnn3.groupid = ''FireProtectionDiscount''
	and nnn3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final llll1
	on a.Fire_Protection_10 = llll1.code  collate SQL_Latin1_General_CP1_CI_AS
	and llll1.relativitytype  = ''Building''
	and llll1.groupid = ''FireProtectionDiscount''
	and llll1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final llll2
	on a.Fire_Protection_10 = llll2.code  collate SQL_Latin1_General_CP1_CI_AS
	and llll2.relativitytype  = ''CSO''
	and llll2.groupid = ''FireProtectionDiscount''
	and llll2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final llll3
	on a.Fire_Protection_10 = llll3.code  collate SQL_Latin1_General_CP1_CI_AS
	and llll3.relativitytype  = ''Peril''
	and llll3.groupid = ''FireProtectionDiscount''
	and llll3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final mmmm1
	on a.Fire_Protection_11 = mmmm1.code  collate SQL_Latin1_General_CP1_CI_AS
	and mmmm1.relativitytype  = ''Building''
	and mmmm1.groupid = ''FireProtectionDiscount''
	and mmmm1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final mmmm2
	on a.Fire_Protection_11 = mmmm2.code  collate SQL_Latin1_General_CP1_CI_AS
	and mmmm2.relativitytype  = ''CSO''
	and mmmm2.groupid = ''FireProtectionDiscount''
	and mmmm2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final mmmm3
	on a.Fire_Protection_11 = mmmm3.code  collate SQL_Latin1_General_CP1_CI_AS
	and mmmm3.relativitytype  = ''Peril''
	and mmmm3.groupid = ''FireProtectionDiscount''
	and mmmm3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final o1
	on o1.code = ''EXTING & REELS'' and o1.relativitytype = ''Building''
	and o1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final o2
	on o2.code = ''EXTING'' and o2.relativitytype = ''Building''
	and o2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final o3
	on o3.code = ''REELS'' and o3.relativitytype = ''Building''
	and o3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final p1
	on p1.code = ''EXTING & REELS'' and p1.relativitytype = ''CSO''
	and p1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final p2
	on p2.code = ''EXTING'' and p2.relativitytype = ''CSO''
	and p2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final p3
	on p3.code = ''REELS'' and p3.relativitytype = ''CSO''
	and p3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final q1
	on q1.code = ''EXTING & REELS'' and q1.relativitytype = ''Peril''
	and q1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final q2
	on q2.code = ''EXTING'' and q2.relativitytype = ''Peril''
	and q2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final q3
	on q3.code = ''REELS'' and q3.relativitytype = ''Peril''
	and q3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final r1
	on r1.code = ''SMOKEMON & SMOKEUNMON'' and r1.relativitytype = ''Building''
	and r1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final r2
	on r2.code = ''SMOKEMON'' and r2.relativitytype = ''Building''
	and r2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final r3
	on r3.code = ''SMOKEUNMON'' and r3.relativitytype = ''Building''
	and r3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final s1
	on s1.code = ''SMOKEMON & SMOKEUNMON'' and s1.relativitytype = ''CSO''
	and s1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final s2
	on s2.code = ''SMOKEMON'' and s2.relativitytype = ''CSO''
	and s2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final s3
	on s3.code = ''SMOKEUNMON'' and s3.relativitytype = ''CSO''
	and s3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final t1
	on t1.code = ''SMOKEMON & SMOKEUNMON'' and t1.relativitytype = ''Peril''
	and t1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final t2
	on t2.code = ''SMOKEMON'' and t2.relativitytype = ''Peril''
	and t2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final t3
	on t3.code = ''SMOKEUNMON'' and t3.relativitytype = ''Peril''
	and t3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final u1
	on u1.groupid = ''FireProtectionDiscount'' and u1.code = ''FIREALARM & BASEALARM'' and u1.relativitytype = ''Building''
	and u1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final u2
	on u2.groupid = ''FireProtectionDiscount'' and u2.code = ''FIREALARM'' and u2.relativitytype = ''Building''
	and u2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final u3
	on u3.groupid = ''FireProtectionDiscount'' and u3.code = ''BASEALARM'' and u3.relativitytype = ''Building''
	and u3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final v1
	on v1.groupid = ''FireProtectionDiscount'' and v1.code = ''FIREALARM & BASEALARM'' and v1.relativitytype = ''CSO''
	and v1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final v2
	on v2.groupid = ''FireProtectionDiscount'' and v2.code = ''FIREALARM'' and v2.relativitytype = ''CSO''
	and v2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final v3
	on v3.groupid = ''FireProtectionDiscount'' and v3.code = ''BASEALARM'' and v3.relativitytype = ''CSO''
	and v3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final w1
	on w1.groupid = ''FireProtectionDiscount'' and  w1.code = ''FIREALARM & BASEALARM'' and w1.relativitytype = ''Peril''
	and w1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final w2
	on w2.groupid = ''FireProtectionDiscount'' and w2.code = ''FIREALARM'' and w2.relativitytype = ''Peril''
	and w2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final w3
	on w3.groupid = ''FireProtectionDiscount'' and w3.code = ''BASEALARM'' and w3.relativitytype = ''Peril''
	and w3.CURRENT_FLAG = ''YES''
'
SET @PD_Emulation_Step4_D='
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final x1
	on x1.groupid = ''FireProtectionDiscountMin'' and x1.code = ''Minimum2'' and x1.relativitytype = ''Building''
	and x1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final x2
	on x2.groupid = ''FireProtectionDiscount'' and x2.code = ''NONE'' and x2.relativitytype = ''Building''
	and x2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final x3
	on x3.groupid = ''FireProtectionDiscountMin'' and x3.code = ''Minimum1'' and x3.relativitytype = ''Building''
	and x3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final y1
	on y1.groupid = ''FireProtectionDiscountMin'' and y1.code = ''Minimum2'' and y1.relativitytype = ''CSO''
	and y1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final y2
	on y2.groupid = ''FireProtectionDiscount'' and y2.code = ''NONE'' and y2.relativitytype = ''CSO''
	and y2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final y3
	on y3.groupid = ''FireProtectionDiscountMin'' and y3.code = ''Minimum1'' and y3.relativitytype = ''CSO''
	and y3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final z1
	on z1.groupid = ''FireProtectionDiscountMin'' and z1.code = ''Minimum2'' and z1.relativitytype = ''Peril''
	and z1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final z2
	on z2.groupid = ''FireProtectionDiscount'' and z2.code = ''NONE'' and z2.relativitytype = ''Peril''
	and z2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final z3
	on z3.groupid = ''FireProtectionDiscountMin'' and z3.code = ''Minimum1'' and z3.relativitytype = ''Peril''
	and z3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final ba1
	on ba1.groupid = ''FireProtectionDiscountMin'' and ba1.code = ''Minimum2'' and ba1.relativitytype = ''Building''
	and ba1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final ba2
	on ba2.groupid = ''FireProtectionDiscountMin'' and ba2.code = ''Minimum1'' and ba2.relativitytype = ''Building''
	and ba2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final bb1
	on bb1.groupid = ''FireProtectionDiscountMin'' and bb1.code = ''Minimum2'' and bb1.relativitytype = ''CSO''
	and bb1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final bb2
	on bb2.groupid = ''FireProtectionDiscountMin'' and bb2.code = ''Minimum1'' and bb2.relativitytype = ''CSO''
	and bb2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final bc1
	on bc1.groupid = ''FireProtectionDiscountMin'' and bc1.code = ''Minimum2'' and bc1.relativitytype = ''Peril''
	and bc1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final bc2
	on bc2.groupid = ''FireProtectionDiscountMin'' and bc2.code = ''Minimum1'' and bc2.relativitytype = ''Peril''
	and bc2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final bd1
	on bd1.groupid = ''FireProtectionLoading'' and bd1.code = ''NO EXTING'' and bd1.relativitytype = ''Building''
	and bd1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final bd2
	on bd2.groupid = ''FireProtectionLoading'' and bd2.code = ''NO EXTING'' and bd2.relativitytype = ''CSO''
	and bd2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final bd3
	on bd3.groupid = ''FireProtectionLoading'' and bd3.code = ''NO EXTING'' and bd3.relativitytype = ''Peril''
	and bd3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final be1
	on be1.groupid = ''FireProtectionLoading'' and be1.code = ''NO REELS'' and be1.relativitytype = ''Building''
	and be1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final be2
	on be2.groupid = ''FireProtectionLoading'' and be2.code = ''NO REELS'' and be2.relativitytype = ''CSO''
	and be2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final be3
	on be3.groupid = ''FireProtectionLoading'' and be3.code = ''NO REELS'' and be3.relativitytype = ''Peril''
	and be3.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final bf1
	on bf1.groupid = ''FireProtectionSprinklers'' and bf1.code = ''DUAL01'' collate SQL_Latin1_General_CP1_CI_AS
	and bf1.rangefield = case when a.Channel in (''STEADFAST_BUSINESS_PACK_PRODUCT'') Then case when a.PercentSprinklerCoverage = 100 then ''Yes'' else ''No'' end + coalesce(cast(a.SprinklerStandards as varchar),''No'')  collate SQL_Latin1_General_CP1_CI_AS
		When a.Channel in (''CALIBRE_BUSINESS_PACK_PRODUCT'',''BIZCOVER_BUSINESS_PACK_PRODUCT'') then ''Yes'' + case when a.PercentSprinklerCoverage = 100 then ''Yes'' else ''No'' end collate SQL_Latin1_General_CP1_CI_AS else ''NoNo'' end 
	and bf1.relativitytype = ''Building''
	and bf1.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final bf2
	on bf2.groupid = ''FireProtectionSprinklers'' and bf2.code = ''DUAL01'' collate SQL_Latin1_General_CP1_CI_AS
	and bf2.rangefield = case when a.Channel in (''STEADFAST_BUSINESS_PACK_PRODUCT'') Then case when a.PercentSprinklerCoverage = 100 then ''Yes'' else ''No'' end + coalesce(cast(a.SprinklerStandards as varchar),''No'')  collate SQL_Latin1_General_CP1_CI_AS
		When a.Channel in (''CALIBRE_BUSINESS_PACK_PRODUCT'',''BIZCOVER_BUSINESS_PACK_PRODUCT'') then ''Yes'' + case when a.PercentSprinklerCoverage = 100 then ''Yes'' else ''No'' end collate SQL_Latin1_General_CP1_CI_AS else ''NoNo'' end 
	and bf2.relativitytype = ''CSO'' --change from Building to CSO in
	and bf2.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final bf3
	on bf3.groupid = ''FireProtectionSprinklers'' and bf3.code = ''DUAL01'' collate SQL_Latin1_General_CP1_CI_AS
	and bf3.rangefield = case when a.Channel in (''STEADFAST_BUSINESS_PACK_PRODUCT'') Then case when a.PercentSprinklerCoverage = 100 then ''Yes'' else ''No'' end + coalesce(cast(a.SprinklerStandards as varchar),''No'')  collate SQL_Latin1_General_CP1_CI_AS
		When a.Channel in (''CALIBRE_BUSINESS_PACK_PRODUCT'',''BIZCOVER_BUSINESS_PACK_PRODUCT'') then ''Yes'' + case when a.PercentSprinklerCoverage = 100 then ''Yes'' else ''No'' end collate SQL_Latin1_General_CP1_CI_AS else ''NoNo'' end 
	and bf3.relativitytype = ''Peril'' --change from Building to Peril in
	and bf3.CURRENT_FLAG = ''YES''
;'
;

------------------------------------------------------------------------------
--- Max_Loading_for_EXTING_REELS Rel - (1 sec)
------------------------------------------------------------------------------
SET @PD_Emulation_Step5='
drop table if exists   CalibreSSiSdev.emula.OM_property_pre_2_temp2_'+@suffix+'_'+@version+';

select 
	a.*
	, case when cast(EXTING_NONE_Building as numeric(15,5)) * cast(REELS_NONE_Building as numeric(15,5)) < b.value --(1.15 or 1)*(1.02 or 1) compare to b.value=1.15 
			then cast(EXTING_NONE_Building as numeric(15,5)) * cast(REELS_NONE_Building as numeric(15,5)) 
		 else b.value end as Max_Loading_for_EXTING_REELS_BUILDING--b.value =1.15
	, case when cast(EXTING_NONE_CSO as numeric(15,5)) * cast(REELS_NONE_CSO as numeric(15,5)) < b.value 
			then cast(EXTING_NONE_CSO as numeric(15,5)) * cast(REELS_NONE_CSO as numeric(15,5))
		 else c.value end as Max_Loading_for_EXTING_REELS_CSO--b.value =1.15
	, case when cast(EXTING_NONE_Peril as numeric(15,5)) * cast(REELS_NONE_Peril as numeric(15,5)) < b.value 
			then cast(EXTING_NONE_Peril as numeric(15,5)) * cast(REELS_NONE_Peril as numeric(15,5))
		 else d.value end as Max_Loading_for_EXTING_REELS_Peril--b.value =1.15
into CalibreSSiSdev.emula.OM_property_pre_2_temp2_'+@suffix+'_'+@version+'
from CalibreSSiSdev.emula.OM_property_pre_2_temp_'+@suffix+'_'+@version+' a 
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final b
	on b.groupid = ''FireProtectionLoadingMax'' and b.relativitytype = ''Building''
	and b.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final c
	on c.groupid = ''FireProtectionLoadingMax'' and c.relativitytype = ''CSO''
	and c.CURRENT_FLAG = ''YES''
left join CalibreSSiSdev.dbo.ccomm_businessproperty_final d
	on d.groupid = ''FireProtectionLoadingMax'' and d.relativitytype = ''Peril''
	and d.CURRENT_FLAG = ''YES''
;'
;


-----------------------------------------------------------------------------------------------------------------------------------
--- (3 sec) - Fire_Protection_Rel_Building * Fire_Protection_Loading_Relativity_Building (PENALTY) = Fire_Protection_Combined_Building-----------------
-----------------------------------------------------------------------------------------------------------------------------------

SET @PD_Emulation_Step6='

drop table if exists  CalibreSSiSdev.emula.OM_property_pre_2_'+@suffix+'_'+@version+';

with OM_propety_2_temp_'+@suffix+'_'+@version+' as (
select 
	a.*
	, case when Fire_Protection_1_to_11 = 0 then d.value --''FireProtectionDiscount'' ''None''
		 when a.PercentSprinklerCoverage = 100 then
			(
			select max(Fire_Protection_Rel2) from 
			(values(a.Min_Rel_Max_Discount_Fire_2_Building), --0.8/0.75
			( 
			(select max(Fire_Protection_Rel) from 
			(values(Min_Rel_Max_Discount_Fire_1_Building), --0.8/0.75/1.365
			(FP1_Building_Rel*FP2_Building_Rel*FP3_Building_Rel*FP4_Building_Rel*FP5_Building_Rel* --FP(1-11)_Building_Rel: rel from those single fire protection
			 FP6_Building_Rel*FP7_Building_Rel*FP8_Building_Rel*FP9_Building_Rel*
			 FP10_Building_Rel*FP11_Building_Rel*SMOKEMON_SMOKEUNMON_Building*FIREALARM_BASEALARM_Building
			 *EXTING_REELS_BUILDING) --added in after testig UAT 2022
			) as b(Fire_Protection_Rel)) * Sprinklers_Building))  as b(Fire_Protection_Rel2)) ----Sprinklers_Building: (y)100%sprinkle+(y)standardsprinkle->0.7; others 1.
		else
			(select max(Fire_Protection_Rel2) from 
			(values (Min_Rel_Max_Discount_Fire_2_Building), 
			((select max(Fire_Protection_Rel)  from 
			(values(Min_Rel_Max_Discount_Fire_1_Building),
			(FP1_Building_Rel*FP2_Building_Rel*FP3_Building_Rel*FP4_Building_Rel*FP5_Building_Rel*
			 FP6_Building_Rel*FP7_Building_Rel*FP8_Building_Rel*FP9_Building_Rel*
			 FP10_Building_Rel*FP11_Building_Rel*SMOKEMON_SMOKEUNMON_Building*FIREALARM_BASEALARM_Building
			 *EXTING_REELS_BUILDING) --added in after testig UAT 2022
			) as b(Fire_Protection_Rel)))) as b(Fire_Protection_Rel2)) --no sprinkle in this situation
		END AS  Fire_Protection_Rel_Building
	, case when Fire_Protection_1_to_11 = 0 then e.value --''FireProtectionDiscount'' ''None'' -CSO
		   when PercentSprinklerCoverage = 100 then 
				(select max(Fire_Protection_Rel2) from --0.85
					(values (Min_Rel_Max_Discount_Fire_2_CSO),
						((select max(Fire_Protection_Rel)  from 
							(values(Min_Rel_Max_Discount_Fire_1_CSO), --0.66
							(FP1_CSO_Rel*FP2_CSO_Rel*FP3_CSO_Rel*FP4_CSO_Rel*FP5_CSO_Rel*FP6_CSO_Rel*FP7_CSO_Rel*
							 FP8_CSO_Rel*FP9_CSO_Rel*FP10_CSO_Rel*FP11_CSO_Rel*SMOKEMON_SMOKEUNMON_CSO*FIREALARM_BASEALARM_CSO
							 *EXTING_REELS_CSO)--added in after testig UA
							) as b(Fire_Protection_Rel)) * Sprinklers_CSO )) --Sprinklers_CSO
				as b(Fire_Protection_Rel2))
			else
				 (select max(Fire_Protection_Rel2) from 
				 (values (Min_Rel_Max_Discount_Fire_2_CSO),
				((select max(Fire_Protection_Rel)  from 
				(values(Min_Rel_Max_Discount_Fire_1_CSO),
				(FP1_CSO_Rel*FP2_CSO_Rel*FP3_CSO_Rel*FP4_CSO_Rel*FP5_CSO_Rel*FP6_CSO_Rel*FP7_CSO_Rel*
				 FP8_CSO_Rel*FP9_CSO_Rel*FP10_CSO_Rel*FP11_CSO_Rel*SMOKEMON_SMOKEUNMON_CSO*FIREALARM_BASEALARM_CSO
				 *EXTING_REELS_CSO) --added in after testig UAT 2022
				) as b(Fire_Protection_Rel)))) as b(Fire_Protection_Rel2))
			END AS  Fire_Protection_Rel_CSO
	, case when Fire_Protection_1_to_11 = 0 then f.value 
		   when PercentSprinklerCoverage = 100 then
				(select max(Fire_Protection_Rel2) from 
				(values(Min_Rel_Max_Discount_Fire_2_Peril),
				((select max(Fire_Protection_Rel)  from 
				(values(Min_Rel_Max_Discount_Fire_1_Peril),
				(FP1_Peril_Rel*FP2_Peril_Rel*FP3_Peril_Rel*FP4_Peril_Rel*FP5_Peril_Rel*FP6_Peril_Rel*
				 FP7_Peril_Rel*FP8_Peril_Rel*FP9_Peril_Rel*FP10_Peril_Rel*FP11_Peril_Rel*SMOKEMON_SMOKEUNMON_Peril*FIREALARM_BASEALARM_Peril
				 *EXTING_REELS_Peril) --added in after testig UAT 2022 
				) as b(Fire_Protection_Rel)) * Sprinklers_Peril)) as b(Fire_Protection_Rel2))
		else
				 (select max(Fire_Protection_Rel2) from 
				 (values  (Min_Rel_Max_Discount_Fire_2_Peril),
				((select max(Fire_Protection_Rel)  from 
				(values(Min_Rel_Max_Discount_Fire_1_Peril),
				(FP1_Peril_Rel*FP2_Peril_Rel*FP3_Peril_Rel*FP4_Peril_Rel*FP5_Peril_Rel*FP6_Peril_Rel*
				 FP7_Peril_Rel*FP8_Peril_Rel*FP9_Peril_Rel*FP10_Peril_Rel*FP11_Peril_Rel*SMOKEMON_SMOKEUNMON_Peril*FIREALARM_BASEALARM_Peril
				 *EXTING_REELS_Peril) --added in after testig UAT 2022
				) as b(Fire_Protection_Rel)))) as b(Fire_Protection_Rel2))
	END AS  Fire_Protection_Rel_Peril
 from CalibreSSiSdev.emula.OM_property_pre_2_temp2_'+@suffix+'_'+@version+' a
 left join CalibreSSiSdev.dbo.ccomm_businessproperty_final d
	 on d.groupid = ''FireProtectionDiscount'' and d.code = ''NONE'' and d.relativitytype = ''Building''
 left join CalibreSSiSdev.dbo.ccomm_businessproperty_final e
	  on e.groupid = ''FireProtectionDiscount'' and e.code = ''NONE'' and e.relativitytype = ''CSO''
 left join CalibreSSiSdev.dbo.ccomm_businessproperty_final f
	  on f.groupid = ''FireProtectionDiscount'' and f.code = ''NONE'' and f.relativitytype = ''Peril''
),

OM_property_2_temp2_'+@suffix+'_'+@version+' as (
select 
	a.*
	, case when a.Fire_Protection_0 = ''NONE'' or --distinct Fire_Protection_0: null or NONE
		( 
			(a.Channel in (''STEADFAST_BUSINESS_PACK_PRODUCT'') and a.Fire_Protection_3 = ''SPRINK'' and ((SprinklerStandards = ''YES'' and SprinklerWaterType is not null) )) 
		Or ( a.Channel in (''CALIBRE_BUSINESS_PACK_PRODUCT'', ''BIZCOVER_BUSINESS_PACK_PRODUCT'') and PercentSprinklerCoverage = 100 and (SprinklerStandards = ''YES'' and SprinklerWaterType is not null) )
		
		) then 1
		 when a.Fire_Protection_1 is null and a.Fire_Protection_2 is null then --no exting or reel
			Max_Loading_for_EXTING_REELS_BUILDING --cast(EXTING_NONE_Building as numeric(15,5)) * cast(REELS_NONE_Building as numeric(15,5)) -> --(1.15 or 1)*(1.02 or 1)
		when a.Fire_Protection_1 is null and a.Fire_Protection_2 is not null then -- no exting but reels exists
			EXTING_NONE_BUILDING
		when a.Fire_Protection_1 is not null and a.Fire_Protection_2 is null then -- no reels but exting exists
			REELS_NONE_Building   
			else 1 end as Fire_Protection_Loading_Relativity_Building
	, case when a.Fire_Protection_0 = ''NONE'' or 
		( 
			(a.Channel in (''STEADFAST_BUSINESS_PACK_PRODUCT'') and a.Fire_Protection_3 = ''SPRINK'' and ((SprinklerStandards = ''YES'' and SprinklerWaterType is not null) )) 
		Or ( a.Channel in (''CALIBRE_BUSINESS_PACK_PRODUCT'', ''BIZCOVER_BUSINESS_PACK_PRODUCT'') and PercentSprinklerCoverage = 100 and (SprinklerStandards = ''YES'' and SprinklerWaterType is not null) )
		
		) then 1
		 when a.Fire_Protection_1 is null and a.Fire_Protection_2 is null then 
			Max_Loading_for_EXTING_REELS_CSO
		when a.Fire_Protection_1 is null and a.Fire_Protection_2 is not null then 
			EXTING_NONE_CSO 
		when a.Fire_Protection_1 is not null and a.Fire_Protection_2 is null then
			REELS_NONE_CSO
			else 1 end as Fire_Protection_Loading_Relativity_CSO
	, case when a.Fire_Protection_0 = ''NONE'' or 
		( 
			(a.Channel in (''STEADFAST_BUSINESS_PACK_PRODUCT'') and a.Fire_Protection_3 = ''SPRINK'' and ((SprinklerStandards = ''YES'' and SprinklerWaterType is not null) )) 
		Or ( a.Channel in (''CALIBRE_BUSINESS_PACK_PRODUCT'', ''BIZCOVER_BUSINESS_PACK_PRODUCT'') and PercentSprinklerCoverage = 100 and (SprinklerStandards = ''YES'' and SprinklerWaterType is not null) )
		
		) then 1
		 when a.Fire_Protection_1 is null and a.Fire_Protection_2 is null then 
			Max_Loading_for_EXTING_REELS_Peril
		when a.Fire_Protection_1 is null and a.Fire_Protection_2 is not null then 
			EXTING_NONE_Peril
			when a.Fire_Protection_1 is not null and a.Fire_Protection_2 is null then
			REELS_NONE_Peril 
			else 1 end as Fire_Protection_Loading_Relativity_Peril
from OM_propety_2_temp_'+@suffix+'_'+@version+' a  
)
select 
	a.*
	, Fire_Protection_Loading_Relativity_Building * Fire_Protection_Rel_Building as Fire_Protection_Combined_Building
	, Fire_Protection_Loading_Relativity_CSO * Fire_Protection_Rel_CSO as Fire_Protection_Combined_CSO
	, Fire_Protection_Loading_Relativity_Peril * Fire_Protection_Rel_Peril as Fire_Protection_Combined_Peril
into CalibreSSiSdev.emula.OM_property_pre_2_'+@suffix+'_'+@version+'
From OM_property_2_temp2_'+@suffix+'_'+@version+' a 
;'
;



------------------------------------------------------------------------------
---Security Protection Rel - (3 mins)
------------------------------------------------------------------------------



SET @PD_Emulation_Step7_A='
drop table if exists  CalibreSSiSdev.emula.OM_property_pre_3_temp_'+@suffix+'_'+@version+';

with property_pre_3_temp_'+@suffix+'_'+@version+' as (
select 
	a.*
	, case when a.Security_Protection_0 = ''NONE'' then coalesce(b11.value,''1'')
		else ''1'' end as SP_0_Building
	, case when a.Security_Protection_0 = ''NONE'' then coalesce(b12.value,''1'')
		else ''1'' end as SP_0_CSO
	, case when a.Security_Protection_0 = ''NONE'' then coalesce(b13.value,''1'')
		else ''1'' end as SP_0_Peril
	, case when a.Security_Protection_0 = ''NONE'' then coalesce(b14.value,''1'')
		else ''1'' end as SP_0_Theft
	, case when a.Security_Protection_0 = ''NONE'' then coalesce(b15.value,''1'')
		else ''1'' end as SP_0_Money
	, case when a.Security_Protection_0 = ''NONE'' then coalesce(b16.value,''1'')
		else ''1'' end as SP_0_Glass

	, case when a.Security_Protection_1 = ''LOCALALARM'' then coalesce(b21.value,''1'')
		else ''1'' end as SP_1_Building
	, case when a.Security_Protection_1 = ''LOCALALARM'' then coalesce(b22.value,''1'')
		else ''1'' end as SP_1_CSO
	, case when a.Security_Protection_1 = ''LOCALALARM'' then coalesce(b23.value,''1'')
		else ''1'' end as SP_1_Peril
	, case when a.Security_Protection_1 = ''LOCALALARM'' then coalesce(b24.value,''1'')
		else ''1'' end as SP_1_Theft
	, case when a.Security_Protection_1 = ''LOCALALARM'' then coalesce(b25.value,''1'')
		else ''1'' end as SP_1_Money
	, case when a.Security_Protection_1 = ''LOCALALARM'' then coalesce(b26.value,''1'')
		else ''1'' end as SP_1_Glass

	, case when a.Security_Protection_2 = ''BASEALARM'' then coalesce(b31.value,''1'')
		else ''1'' end as SP_2_Building
	, case when a.Security_Protection_2 = ''BASEALARM'' then coalesce(b32.value,''1'')
		else ''1'' end as SP_2_CSO
	, case when a.Security_Protection_2 = ''BASEALARM'' then coalesce(b33.value,''1'')
		else ''1'' end as SP_2_Peril
	, case when a.Security_Protection_2 = ''BASEALARM'' then coalesce(b34.value,''1'')
		else ''1'' end as SP_2_Theft
	, case when a.Security_Protection_2 = ''BASEALARM'' then coalesce(b35.value,''1'')
		else ''1'' end as SP_2_Money
	, case when a.Security_Protection_2 = ''BASEALARM'' then coalesce(b36.value,''1'')
		else ''1'' end as SP_2_Glass

	, case when a.Security_Protection_3 = ''WINDOWBARS'' then coalesce(b41.value,''1'')
		else ''1'' end as SP_3_Building
	, case when a.Security_Protection_3 = ''WINDOWBARS'' then coalesce(b42.value,''1'')
		else ''1'' end as SP_3_CSO
	, case when a.Security_Protection_3 = ''WINDOWBARS'' then coalesce(b43.value,''1'')
		else ''1'' end as SP_3_Peril
	, case when a.Security_Protection_3 = ''WINDOWBARS'' then coalesce(b44.value,''1'') --KL: change from BASEALARM to WINDOWBARS
		else ''1'' end as SP_3_Theft
	, case when a.Security_Protection_3 = ''WINDOWBARS'' then coalesce(b45.value,''1'')--KL: change from BASEALARM to WINDOWBARS
		else ''1'' end as SP_3_Money
	, case when a.Security_Protection_3 = ''WINDOWBARS'' then coalesce(b46.value,''1'')--KL: change from BASEALARM to WINDOWBARS
		else ''1'' end as SP_3_Glass

	, case when a.Security_Protection_4 = ''WINDOWLOCKS'' then coalesce(b51.value,''1'')
		else ''1'' end as SP_4_Building
	, case when a.Security_Protection_4 = ''WINDOWLOCKS'' then coalesce(b52.value,''1'')
		else ''1'' end as SP_4_CSO
	, case when a.Security_Protection_4 = ''WINDOWLOCKS'' then coalesce(b53.value,''1'')
		else ''1'' end as SP_4_Peril
	, case when a.Security_Protection_4 = ''WINDOWLOCKS'' then coalesce(b54.value,''1'')
		else ''1'' end as SP_4_Theft
	, case when a.Security_Protection_4 = ''WINDOWLOCKS'' then coalesce(b55.value,''1'')
		else ''1'' end as SP_4_Money
	, case when a.Security_Protection_4 = ''WINDOWLOCKS'' then coalesce(b56.value,''1'')
		else ''1'' end as SP_4_Glass

	, case when a.Security_Protection_5 = ''DEADLOCKS'' then coalesce(b61.value,''1'')
		else ''1'' end as SP_5_Building
	, case when a.Security_Protection_5 = ''DEADLOCKS'' then coalesce(b62.value,''1'')
		else ''1'' end as SP_5_CSO
	, case when a.Security_Protection_5 = ''DEADLOCKS'' then coalesce(b63.value,''1'')
		else ''1'' end as SP_5_Peril
	, case when a.Security_Protection_5 = ''DEADLOCKS'' then coalesce(b64.value,''1'')
		else ''1'' end as SP_5_Theft
	, case when a.Security_Protection_5 = ''DEADLOCKS'' then coalesce(b65.value,''1'')
		else ''1'' end as SP_5_Money
	, case when a.Security_Protection_5 = ''DEADLOCKS'' then coalesce(b66.value,''1'')
		else ''1'' end as SP_5_Glass

	, case when a.Security_Protection_6 = ''DISPLAYWINDOW'' then coalesce(b71.value,''1'')
		else ''1'' end as SP_6_Building
	, case when a.Security_Protection_6 = ''DISPLAYWINDOW'' then coalesce(b72.value,''1'')
		else ''1'' end as SP_6_CSO
	, case when a.Security_Protection_6 = ''DISPLAYWINDOW'' then coalesce(b73.value,''1'')
		else ''1'' end as SP_6_Peril
	, case when a.Security_Protection_6 = ''DISPLAYWINDOW'' then coalesce(b74.value,''1'')
		else ''1'' end as SP_6_Theft
	, case when a.Security_Protection_6 = ''DISPLAYWINDOW'' then coalesce(b75.value,''1'')
		else ''1'' end as SP_6_Money
	, case when a.Security_Protection_6 = ''DISPLAYWINDOW'' then coalesce(b76.value,''1'')
		else ''1'' end as SP_6_Glass

	, case when a.Security_Protection_7 = ''LIGHTS'' then coalesce(b81.value,''1'')
		else ''1'' end as SP_7_Building
	, case when a.Security_Protection_7 = ''LIGHTS'' then coalesce(b82.value,''1'')
		else ''1'' end as SP_7_CSO
	, case when a.Security_Protection_7 = ''LIGHTS'' then coalesce(b83.value,''1'')
		else ''1'' end as SP_7_Peril
	, case when a.Security_Protection_7 = ''LIGHTS'' then coalesce(b84.value,''1'')
		else ''1'' end as SP_7_Theft
	, case when a.Security_Protection_7 = ''LIGHTS'' then coalesce(b85.value,''1'')
		else ''1'' end as SP_7_Money
	, case when a.Security_Protection_7 = ''LIGHTS'' then coalesce(b86.value,''1'')
		else ''1'' end as SP_7_Glass

	, case when a.Security_Protection_8 = ''BOLLARDS'' then coalesce(b91.value,''1'')
		else ''1'' end as SP_8_Building
	, case when a.Security_Protection_8 = ''BOLLARDS'' then coalesce(b92.value,''1'')
		else ''1'' end as SP_8_CSO
	, case when a.Security_Protection_8 = ''BOLLARDS'' then coalesce(b93.value,''1'')
		else ''1'' end as SP_8_Peril
	, case when a.Security_Protection_8 = ''BOLLARDS'' then coalesce(b94.value,''1'')
		else ''1'' end as SP_8_Theft
	, case when a.Security_Protection_8 = ''BOLLARDS'' then coalesce(b95.value,''1'')
		else ''1'' end as SP_8_Money
	, case when a.Security_Protection_8 = ''BOLLARDS'' then coalesce(b96.value,''1'')
		else ''1'' end as SP_8_Glass

	, case when a.Security_Protection_9 = ''CCTV'' then coalesce(b101.value,''1'')
		else ''1'' end as SP_9_Building
	, case when a.Security_Protection_9 = ''CCTV'' then coalesce(b102.value,''1'')
		else ''1'' end as SP_9_CSO
	, case when a.Security_Protection_9 = ''CCTV'' then coalesce(b103.value,''1'')
		else ''1'' end as SP_9_Peril
	, case when a.Security_Protection_9 = ''CCTV'' then coalesce(b104.value,''1'')
		else ''1'' end as SP_9_Theft
	, case when a.Security_Protection_9 = ''CCTV'' then coalesce(b105.value,''1'')
		else ''1'' end as SP_9_Money
	, case when a.Security_Protection_9 = ''CCTV'' then coalesce(b106.value,''1'')
		else ''1'' end as SP_9_Glass

	, case when a.Security_Protection_10 = ''FENCING'' then coalesce(b111.value,''1'')
		else ''1'' end as SP_10_Building
	, case when a.Security_Protection_10 = ''FENCING'' then coalesce(b112.value,''1'')
		else ''1'' end as SP_10_CSO
	, case when a.Security_Protection_10 = ''FENCING'' then coalesce(b113.value,''1'')
		else ''1'' end as SP_10_Peril
	, case when a.Security_Protection_10 = ''FENCING'' then coalesce(b114.value,''1'')
		else ''1'' end as SP_10_Theft
	, case when a.Security_Protection_10 = ''FENCING'' then coalesce(b115.value,''1'')
		else ''1'' end as SP_10_Money
	, case when a.Security_Protection_10 = ''FENCING'' then coalesce(b116.value,''1'')
		else ''1'' end as SP_10_Glass

	, case when a.Security_Protection_11 = ''PATROLS'' then coalesce(b121.value,''1'')
		else ''1'' end as SP_11_Building
	, case when a.Security_Protection_11 = ''PATROLS'' then coalesce(b122.value,''1'')
		else ''1'' end as SP_11_CSO
	, case when a.Security_Protection_11 = ''PATROLS'' then coalesce(b123.value,''1'')
		else ''1'' end as SP_11_Peril
	, case when a.Security_Protection_11 = ''PATROLS'' then coalesce(b124.value,''1'')
		else ''1'' end as SP_11_Theft
	, case when a.Security_Protection_11 = ''PATROLS'' then coalesce(b125.value,''1'')
		else ''1'' end as SP_11_Money
	, case when a.Security_Protection_11 = ''PATROLS'' then coalesce(b126.value,''1'')
		else ''1'' end as SP_11_Glass

	, case when a.Security_Protection_12 = ''KEYPAD'' then coalesce(b131.value,''1'')
		else ''1'' end as SP_12_Building
	, case when a.Security_Protection_12 = ''KEYPAD'' then coalesce(b132.value,''1'')
		else ''1'' end as SP_12_CSO
	, case when a.Security_Protection_12 = ''KEYPAD'' then coalesce(b133.value,''1'')
		else ''1'' end as SP_12_Peril
	, case when a.Security_Protection_12 = ''KEYPAD'' then coalesce(b134.value,''1'')
		else ''1'' end as SP_12_Theft
	, case when a.Security_Protection_12 = ''KEYPAD'' then coalesce(b135.value,''1'')
		else ''1'' end as SP_12_Money
	, case when a.Security_Protection_12 = ''KEYPAD'' then coalesce(b136.value,''1'')
		else ''1'' end as SP_12_Glass

	, case when a.Security_Protection_13 = ''SHUTTERS'' then coalesce(b141.value,''1'')
		else ''1'' end as SP_13_Building
	, case when a.Security_Protection_13 = ''SHUTTERS'' then coalesce(b142.value,''1'')
		else ''1'' end as SP_13_CSO
	, case when a.Security_Protection_13 = ''SHUTTERS'' then coalesce(b143.value,''1'')
		else ''1'' end as SP_13_Peril
	, case when a.Security_Protection_13 = ''SHUTTERS'' then coalesce(b144.value,''1'')
		else ''1'' end as SP_13_Theft
	, case when a.Security_Protection_13 = ''SHUTTERS'' then coalesce(b145.value,''1'')
		else ''1'' end as SP_13_Money
	, case when a.Security_Protection_13 = ''SHUTTERS'' then coalesce(b146.value,''1'')
		else ''1'' end as SP_13_Glass

	, case when a.Security_Protection_1_to_13 = 0  then ''1'' else c1.value end as Min_Rel_Max_Dis_SP_Building
	, case when a.Security_Protection_1_to_13 = 0  then ''1'' else c2.value end as Min_Rel_Max_Dis_SP_CSO		            
	, case when a.Security_Protection_1_to_13 = 0  then ''1'' else c3.value end as Min_Rel_Max_Dis_SP_Peril
	, case when a.Security_Protection_1_to_13 = 0  then ''1'' else c4.value end as Min_Rel_Max_Dis_SP_Theft
	, case when a.Security_Protection_1_to_13 = 0  then ''1'' else c5.value end as Min_Rel_Max_Dis_SP_Money	            
	, case when a.Security_Protection_1_to_13 = 0  then ''1'' else c6.value end as Min_Rel_Max_Dis_SP_Glass

	, case when a.locationtype in (''SCTR01'',''SFAB01'') then ''1''
		when a.Security_Protection_5 = ''DEADLOCKS'' then ''1''
		else d1.value end as Deadlocks_None_Loading_Building
	, case when a.locationtype in (''SCTR01'',''SFAB01'') then ''1''
		when a.Security_Protection_5 = ''DEADLOCKS'' then ''1''
		else d2.value end as Deadlocks_None_Loading_CSO
	, case when a.locationtype in (''SCTR01'',''SFAB01'') then ''1''
		when a.Security_Protection_5 = ''DEADLOCKS'' then ''1''
		else d3.value end as Deadlocks_None_Loading_Peril
	, case when a.locationtype in (''SCTR01'',''SFAB01'') then ''1''
		when a.Security_Protection_5 = ''DEADLOCKS'' then ''1''
		else d4.value end as Deadlocks_None_Loading_Theft
	, case when a.locationtype in (''SCTR01'',''SFAB01'') then ''1''
		when a.Security_Protection_5 = ''DEADLOCKS'' then ''1''
		else d5.value end as Deadlocks_None_Loading_Money
	, case when a.locationtype in (''SCTR01'',''SFAB01'') then ''1''
		when a.Security_Protection_5 = ''DEADLOCKS'' then ''1''
		else d6.value end as Deadlocks_None_Loading_Glass
	, case when a.locationtype in (''SCTR01'',''SFAB01'') then ''1''
		when a.Security_Protection_4 = ''WINDOWLOCKS'' then ''1''
		else e1.value end as Windowlocks_None_Loading_Building
	, case when a.locationtype in (''SCTR01'',''SFAB01'') then ''1''
		when a.Security_Protection_4 = ''WINDOWLOCKS'' then ''1''
		else e2.value end as Windowlocks_None_Loading_CSO
	, case when a.locationtype in (''SCTR01'',''SFAB01'') then ''1''
		when a.Security_Protection_4 = ''WINDOWLOCKS'' then ''1''
		else e3.value end as Windowlocks_None_Loading_Peril
	, case when a.locationtype in (''SCTR01'',''SFAB01'') then ''1''
		when a.Security_Protection_4 = ''WINDOWLOCKS'' then ''1''
		else e4.value end as Windowlocks_None_Loading_Theft
	, case when a.locationtype in (''SCTR01'',''SFAB01'') then ''1''
		when a.Security_Protection_4 = ''WINDOWLOCKS'' then ''1''
		else e5.value end as Windowlocks_None_Loading_Money
	, case when a.locationtype in (''SCTR01'',''SFAB01'') then ''1''
		when a.Security_Protection_4 = ''WINDOWLOCKS'' then ''1''
		else e6.value end as Windowlocks_None_Loading_Glass




';

SET @PD_Emulation_Step7_B='
from CalibreSSiSdev.emula.OM_property_pre_2_'+@suffix+'_'+@version+' a 
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''NONE'','''',''Building'') b11
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''NONE'','''',''CSO'') b12
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''NONE'','''',''Peril'') b13
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''NONE'','''',''Theft'') b14
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''NONE'','''',''Money'') b15
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''NONE'','''',''Glass'') b16
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''LOCALALARM'','''',''Building'') b21
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''LOCALALARM'','''',''CSO'') b22
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''LOCALALARM'','''',''Peril'') b23
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''LOCALALARM'','''',''Theft'') b24
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''LOCALALARM'','''',''Money'') b25
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''LOCALALARM'','''',''Glass'') b26
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''BASEALARM'','''',''Building'') b31
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''BASEALARM'','''',''CSO'') b32
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''BASEALARM'','''',''Peril'') b33
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''BASEALARM'','''',''Theft'') b34
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''BASEALARM'','''',''Money'') b35
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''BASEALARM'','''',''Glass'') b36
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''WINDOWBARS'','''',''Building'') b41
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''WINDOWBARS'','''',''CSO'') b42
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''WINDOWBARS'','''',''Peril'') b43
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''WINDOWBARS'','''',''Theft'') b44
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''WINDOWBARS'','''',''Money'') b45
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''WINDOWBARS'','''',''Glass'') b46
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''WINDOWLOCKS'','''',''Building'') b51
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''WINDOWLOCKS'','''',''CSO'') b52
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''WINDOWLOCKS'','''',''Peril'') b53
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''WINDOWLOCKS'','''',''Theft'') b54
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''WINDOWLOCKS'','''',''Money'') b55
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''WINDOWLOCKS'','''',''Glass'') b56
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''DEADLOCKS'','''',''Building'') b61
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''DEADLOCKS'','''',''CSO'') b62
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''DEADLOCKS'','''',''Peril'') b63
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''DEADLOCKS'','''',''Theft'') b64
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''DEADLOCKS'','''',''Money'') b65
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''DEADLOCKS'','''',''Glass'') b66
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''DISPLAYWINDOW'','''',''Building'') b71
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''DISPLAYWINDOW'','''',''CSO'') b72
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''DISPLAYWINDOW'','''',''Peril'') b73
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''DISPLAYWINDOW'','''',''Theft'') b74
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''DISPLAYWINDOW'','''',''Money'') b75
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''DISPLAYWINDOW'','''',''Glass'') b76
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''LIGHTS'','''',''Building'') b81
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''LIGHTS'','''',''CSO'') b82
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''LIGHTS'','''',''Peril'') b83
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''LIGHTS'','''',''Theft'') b84
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''LIGHTS'','''',''Money'') b85
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''LIGHTS'','''',''Glass'') b86
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''BOLLARDS'','''',''Building'') b91
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''BOLLARDS'','''',''CSO'') b92
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''BOLLARDS'','''',''Peril'') b93
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''BOLLARDS'','''',''Theft'') b94
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''BOLLARDS'','''',''Money'') b95
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''BOLLARDS'','''',''Glass'') b96
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''CCTV'','''',''Building'') b101
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''CCTV'','''',''CSO'') b102
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''CCTV'','''',''Peril'') b103
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''CCTV'','''',''Theft'') b104
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''CCTV'','''',''Money'') b105
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''CCTV'','''',''Glass'') b106
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''FENCING'','''',''Building'') b111
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''FENCING'','''',''CSO'') b112
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''FENCING'','''',''Peril'') b113
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''FENCING'','''',''Theft'') b114
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''FENCING'','''',''Money'') b115
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''FENCING'','''',''Glass'') b116
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''PATROLS'','''',''Building'') b121
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''PATROLS'','''',''CSO'') b122
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''PATROLS'','''',''Peril'') b123
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''PATROLS'','''',''Theft'') b124
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''PATROLS'','''',''Money'') b125
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''PATROLS'','''',''Glass'') b126
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''KEYPAD'','''',''Building'') b131
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''KEYPAD'','''',''CSO'') b132
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''KEYPAD'','''',''Peril'') b133
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''KEYPAD'','''',''Theft'') b134
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''KEYPAD'','''',''Money'') b135
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''KEYPAD'','''',''Glass'') b136
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''SHUTTERS'','''',''Building'') b141
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''SHUTTERS'','''',''CSO'') b142
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''SHUTTERS'','''',''Peril'') b143
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''SHUTTERS'','''',''Theft'') b144
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''SHUTTERS'','''',''Money'') b145
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscount'',''SHUTTERS'','''',''Glass'') b146
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscountMin'','''','''',''Building'') c1
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscountMin'','''','''',''CSO'') c2
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscountMin'','''','''',''Peril'') c3
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscountMin'','''','''',''Theft'') c4
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscountMin'','''','''',''Money'') c5
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityDiscountMin'','''','''',''Glass'') c6
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityLoading'',''NODEADLOCKS'','''',''Building'') d1
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityLoading'',''NODEADLOCKS'','''',''CSO'') d2
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityLoading'',''NODEADLOCKS'','''',''Peril'') d3
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityLoading'',''NODEADLOCKS'','''',''Theft'') d4
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityLoading'',''NODEADLOCKS'','''',''Money'') d5
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityLoading'',''NODEADLOCKS'','''',''Glass'') d6
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityLoading'',''NOWINDOWLOCKS'','''',''Building'') e1
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityLoading'',''NOWINDOWLOCKS'','''',''CSO'') e2
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityLoading'',''NOWINDOWLOCKS'','''',''Peril'') e3
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityLoading'',''NOWINDOWLOCKS'','''',''Theft'') e4
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityLoading'',''NOWINDOWLOCKS'','''',''Money'') e5
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityLoading'',''NOWINDOWLOCKS'','''',''Glass'') e6
	),


'
;

SET @PD_Emulation_Step7_C='

property_pre_3_temp2_'+@suffix+'_'+@version+' as (
select 
	a.*
	, case when a.LocationType in (''SFAB01'',''SCTR01'') then ''1'' 
		else (select min(max_rel)
	 from (values (cast(f1.value as numeric(15,5))),(cast(a.deadlocks_none_loading_building as numeric(15,5)) * 
			cast(a.Windowlocks_None_Loading_Building as numeric(15,5)))) b(max_rel)
	) end as Max_Loading_DEADLOCKS_Windowlocks_Building --as SP_Loading_Rel_Building,
	, case when a.LocationType in (''SFAB01'',''SCTR01'') then ''1'' 
		else (select min(max_rel)
	 from (values (cast(f2.value as numeric(15,5))),(cast(a.deadlocks_none_loading_cso as numeric(15,5)) * 
			cast(a.Windowlocks_None_Loading_cso as numeric(15,5)))) b(max_rel)
	) end as Max_Loading_DEADLOCKS_Windowlocks_cso  --as SP_Loading_Rel_CSO,
	, case when a.LocationType in (''SFAB01'',''SCTR01'') then ''1'' 
		else (select min(max_rel)
	 from (values (cast(f3.value as numeric(15,5))),(cast(a.deadlocks_none_loading_peril as numeric(15,5)) * 
			cast(a.Windowlocks_None_Loading_peril as numeric(15,5)))) b(max_rel)
	) end as Max_Loading_DEADLOCKS_Windowlocks_Peril  --as SP_Loading_Rel_Peril,
	, case when a.LocationType in (''SFAB01'',''SCTR01'') then ''1'' 
		else 
	(select min(max_rel)
	 from (values (cast(f4.value as numeric(15,5))),(cast(a.deadlocks_none_loading_theft as numeric(15,5)) * 
			cast(a.Windowlocks_None_Loading_theft as numeric (15,5)))) b(max_rel)
	) end as Max_Loading_DEADLOCKS_Windowlocks_Theft  --as SP_Loading_Rel_Theft,
	, case when a.LocationType in (''SFAB01'',''SCTR01'') then ''1'' 
		else 
	(select min(max_rel)
	 from (values (cast(f5.value as numeric(15,5))),(cast(a.deadlocks_none_loading_money as numeric(15,5)) * 
			cast(a.Windowlocks_None_Loading_money as numeric(15,5)))) b(max_rel)
	) end as Max_Loading_DEADLOCKS_Windowlocks_Money  --as SP_Loading_Rel_Money,
	, case when a.LocationType in (''SFAB01'',''SCTR01'') then ''1''
		else 
	(select min(max_rel)
	 from (values (cast(f6.value as numeric(15,5))),(cast(a.deadlocks_none_loading_Glass as numeric(15,5)) * 
			cast(a.Windowlocks_None_Loading_glass as numeric(15,5)))) b(max_rel)
	) end as Max_Loading_DEADLOCKS_Windowlocks_Glass  --as SP_Loading_Rel_Glass

from property_pre_3_temp_'+@suffix+'_'+@version+' a 
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityLoadingMax'','''','''',''Building'') f1
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityLoadingMax'','''','''',''CSO'') f2
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityLoadingMax'','''','''',''Peril'') f3
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityLoadingMax'','''','''',''Theft'') f4
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityLoadingMax'','''','''',''Money'') f5
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''PhysicalSecurityLoadingMax'','''','''',''Glass'') f6
)
select 
	a.*
	, case when a.Security_Protection_1_to_13 = 0 or a.Security_Protection_0 = ''NONE'' then 1
		 when a.Security_Protection_4 is null and a.Security_Protection_5 is null then 
			Max_Loading_DEADLOCKS_Windowlocks_Building
		when a.Security_Protection_4 is null and a.Security_Protection_5 is not null then 
			windowlocks_none_loading_building
		when a.Security_Protection_4 is not null and a.Security_Protection_5 is null then
			deadlocks_None_Loading_Building
			else 1 end as SP_Loading_Rel_Building
	, case when a.Security_Protection_1_to_13 = 0 or a.Security_Protection_0 = ''NONE'' then 1
		 when a.Security_Protection_4 is null and a.Security_Protection_5 is null then 
			Max_Loading_DEADLOCKS_Windowlocks_cso
		when a.Security_Protection_4 is null and a.Security_Protection_5 is not null then 
			windowlocks_none_loading_cso
		when a.Security_Protection_4 is not null and a.Security_Protection_5 is null then
			deadlocks_None_Loading_cso
			else 1 end as SP_Loading_Rel_cso
	, case when a.Security_Protection_1_to_13 = 0 or a.Security_Protection_0 = ''NONE'' then 1
		 when a.Security_Protection_4 is null and a.Security_Protection_5 is null then 
			Max_Loading_DEADLOCKS_Windowlocks_peril
		when a.Security_Protection_4 is null and a.Security_Protection_5 is not null then 
			Windowlocks_none_loading_peril
		when a.Security_Protection_4 is not null and a.Security_Protection_5 is null then
			deadlocks_None_Loading_peril
			else 1 end as SP_Loading_Rel_peril
	, case when a.Security_Protection_1_to_13 = 0 or a.Security_Protection_0 = ''NONE'' then 1
		 when a.Security_Protection_4 is null and a.Security_Protection_5 is null then 
			Max_Loading_DEADLOCKS_Windowlocks_theft
		when a.Security_Protection_4 is null and a.Security_Protection_5 is not null then 
			Windowlocks_none_loading_theft
		when a.Security_Protection_4 is not null and a.Security_Protection_5 is null then
			deadlocks_None_Loading_theft
			else 1 end as SP_Loading_Rel_theft

	, case when a.Security_Protection_1_to_13 = 0 or a.Security_Protection_0 = ''NONE'' then 1
		 when a.Security_Protection_4 is null and a.Security_Protection_5 is null then 
			Max_Loading_DEADLOCKS_Windowlocks_money
		when a.Security_Protection_4 is null and a.Security_Protection_5 is not null then 
			Windowlocks_none_loading_money
		when a.Security_Protection_4 is not null and a.Security_Protection_5 is null then
			deadlocks_None_Loading_money
			else 1 end as SP_Loading_Rel_money
	, case when a.Security_Protection_1_to_13 = 0 or a.Security_Protection_0 = ''NONE'' then 1
		 when a.Security_Protection_4 is null and a.Security_Protection_5 is null then 
			Max_Loading_DEADLOCKS_Windowlocks_glass
		when a.Security_Protection_4 is null and a.Security_Protection_5 is not null then 
			Windowlocks_none_loading_glass
		when a.Security_Protection_4 is not null and a.Security_Protection_5 is null then
			deadlocks_None_Loading_glass
			else 1 end as SP_Loading_Rel_glass



'
;


SET @PD_Emulation_Step7_D='

	, case when a.Security_Protection_1 = ''LOCALALARM'' then g2.value --''Alarm'',''LOCALONLY''
			else g1.value end as SP_1_Alarm_Building --''Alarm'',''NOALARM'',
	, case when a.Security_Protection_1 = ''LOCALALARM'' then h2.value 
			else h1.value end as SP_1_Alarm_CSO
	, case when a.Security_Protection_1 = ''LOCALALARM'' then i2.value 
			else i1.value end as SP_1_Alarm_Peril
	, case when a.Security_Protection_1 = ''LOCALALARM'' then j2.value 
			else j1.value end as SP_1_Alarm_Theft
	, case when a.Security_Protection_1 = ''LOCALALARM'' then k2.value 
			else k1.value end as SP_1_Alarm_Money
	, case when a.Security_Protection_2 = ''BASEALARM'' then g3.value --''Alarm'',''MONITORONLY'', a.MonitoredBaseAlarmType
			else g1.value end as SP_2_Alarm_Building ----''Alarm'',''NOALARM'',
	, case when a.Security_Protection_2 = ''BASEALARM'' then h3.value 
			else h1.value end as SP_2_Alarm_CSO
	, case when a.Security_Protection_2 = ''BASEALARM'' then i3.value 
			else i1.value end as SP_2_Alarm_Peril
	, case when a.Security_Protection_2 = ''BASEALARM'' then j3.value 
			else j1.value end as SP_2_Alarm_Theft
	, case when a.Security_Protection_2 = ''BASEALARM'' then k3.value 
			else k1.value end as SP_2_Alarm_Money
into CalibreSSiSdev.emula.OM_property_pre_3_temp_'+@suffix+'_'+@version+'
from property_pre_3_temp2_'+@suffix+'_'+@version+' a
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''Alarm'',''NOALARM'','''',''Building'') g1
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''Alarm'',''LOCALONLY'','''',''Building'') g2
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''Alarm'',''MONITORONLY'',a.MonitoredBaseAlarmType,''Building'') g3
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''Alarm'',''NOALARM'','''',''CSO'') h1
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''Alarm'',''LOCALONLY'','''',''CSO'') h2
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''Alarm'',''MONITORONLY'',a.MonitoredBaseAlarmType,''CSO'') h3
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''Alarm'',''NOALARM'','''',''Peril'') i1
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''Alarm'',''LOCALONLY'','''',''Peril'') i2
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''Alarm'',''MONITORONLY'',a.MonitoredBaseAlarmType,''Peril'') i3
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''Alarm'',''NOALARM'','''',''Theft'') j1
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''Alarm'',''LOCALONLY'','''',''Theft'') j2
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''Alarm'',''MONITORONLY'',a.MonitoredBaseAlarmType,''Theft'') j3
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''Alarm'',''NOALARM'','''',''Money'') k1
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''Alarm'',''LOCALONLY'','''',''Money'') k2
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''Alarm'',''MONITORONLY'',a.MonitoredBaseAlarmType,''Money'') k3
	;

drop table if exists  CalibreSSiSdev.emula.OM_property_pre_3_'+@suffix+'_'+@version+';

with temp3_'+@suffix+'_'+@version+' as (
select 
	a.*
	, case when a.Security_Protection_1 = ''LOCALALARM''
		and a.Security_Protection_2 = ''BASEALARM'' then g1.value  --''Alarm'',''LOCALMONITOR'', ,a.MonitoredBaseAlarmType
		else cast(SP_1_Alarm_Building as numeric(15,5)) * cast(SP_2_Alarm_Building as numeric(15,5))
		end as Alamr_Rel_Buildling
	, case when a.Security_Protection_1 = ''LOCALALARM''
		and a.Security_Protection_2 = ''BASEALARM'' then g2.value 
		else cast(SP_1_Alarm_CSO as numeric(15,5)) * cast(SP_2_Alarm_CSO as numeric(15,5))
		end as Alamr_Rel_CSO
	, case when a.Security_Protection_1 = ''LOCALALARM''
		and a.Security_Protection_2 = ''BASEALARM'' then g3.value 
		else cast(SP_1_Alarm_Peril as numeric(15,5)) * cast(SP_2_Alarm_Peril as numeric(15,5))
		end as Alamr_Rel_Peril
	, case when a.Security_Protection_1 = ''LOCALALARM''
		and a.Security_Protection_2 = ''BASEALARM'' then g4.value 
		else cast(SP_1_Alarm_Theft as numeric(15,5)) * cast(SP_2_Alarm_Theft as numeric(15,5))
		end as Alamr_Rel_Theft
	, case when a.Security_Protection_1 = ''LOCALALARM''
		and a.Security_Protection_2 = ''BASEALARM'' then g5.value 
		else cast(SP_1_Alarm_Money as numeric(15,5)) * cast(SP_2_Alarm_Money as numeric(15,5))
		end as Alamr_Rel_Money
	, cast(SP_1_Building as numeric(15,5)) * cast(SP_2_Building as numeric(15,5)) *
		cast(SP_3_Building as numeric(15,5)) *cast(SP_4_Building as numeric(15,5)) *
		cast(SP_5_Building as numeric(15,5)) *cast(SP_6_Building as numeric(15,5)) *
		cast(SP_7_Building as numeric(15,5)) *cast(SP_8_Building as numeric(15,5)) *
		cast(SP_9_Building as numeric(15,5)) *cast(SP_10_Building as numeric(15,5)) *
		cast(SP_11_Building as numeric(15,5)) *cast(SP_12_Building as numeric(15,5)) * cast(SP_13_Building as numeric(15,5)) as SP_Building_Rel
	, cast(SP_1_CSO as numeric(15,5)) * cast(SP_2_CSO as numeric(15,5)) *
		cast(SP_3_CSO as numeric(15,5)) *cast(SP_4_CSO as numeric(15,5)) *
		cast(SP_5_CSO as numeric(15,5)) *cast(SP_6_CSO as numeric(15,5)) *
		cast(SP_7_CSO as numeric(15,5)) *cast(SP_8_CSO as numeric(15,5)) *
		cast(SP_9_CSO as numeric(15,5)) *cast(SP_10_CSO as numeric(15,5)) *
		cast(SP_11_CSO as numeric(15,5)) *cast(SP_12_CSO as numeric(15,5)) * cast(SP_13_CSO as numeric(15,5)) as SP_CSO_Rel
	, cast(SP_1_Peril as numeric(15,5)) * cast(SP_2_Peril as numeric(15,5)) *
		cast(SP_3_Peril as numeric(15,5)) *cast(SP_4_Peril as numeric(15,5)) *
		cast(SP_5_Peril as numeric(15,5)) *cast(SP_6_Peril as numeric(15,5)) *
		cast(SP_7_Peril as numeric(15,5)) *cast(SP_8_Peril as numeric(15,5)) *
		cast(SP_9_Peril as numeric(15,5)) *cast(SP_10_Peril as numeric(15,5)) *
		cast(SP_11_Peril as numeric(15,5)) *cast(SP_12_Peril as numeric(15,5)) * cast(SP_13_Peril as numeric(15,5)) as SP_Peril_Rel
	, cast(SP_1_Theft as numeric(15,5)) * cast(SP_2_Theft as numeric(15,5)) *
		cast(SP_3_Theft as numeric(15,5)) *cast(SP_4_Theft as numeric(15,5)) *
		cast(SP_5_Theft as numeric(15,5)) *cast(SP_6_Theft as numeric(15,5)) *
		cast(SP_7_Theft as numeric(15,5)) *cast(SP_8_Theft as numeric(15,5)) *
		cast(SP_9_Theft as numeric(15,5)) *cast(SP_10_Theft as numeric(15,5)) *
		cast(SP_11_Theft as numeric(15,5)) *cast(SP_12_Theft as numeric(15,5)) * cast(SP_13_Theft as numeric(15,5)) as SP_Theft_Rel
	, cast(SP_1_Money as numeric(15,5)) * cast(SP_2_Money as numeric(15,5)) *
		cast(SP_3_Money as numeric(15,5)) *cast(SP_4_Money as numeric(15,5)) *
		cast(SP_5_Money as numeric(15,5)) *cast(SP_6_Money as numeric(15,5)) *
		cast(SP_7_Money as numeric(15,5)) *cast(SP_8_Money as numeric(15,5)) *
		cast(SP_9_Money as numeric(15,5)) *cast(SP_10_Money as numeric(15,5)) *
		cast(SP_11_Money as numeric(15,5)) *cast(SP_12_Money as numeric(15,5)) * cast(SP_13_Money as numeric(15,5)) as SP_Money_Rel


'
;

SET @PD_Emulation_Step7_E='

	, cast(SP_1_Glass as numeric(15,5)) * cast(SP_2_Glass as numeric(15,5)) *
		cast(SP_3_Glass as numeric(15,5)) *cast(SP_4_Glass as numeric(15,5)) *
		cast(SP_5_Glass as numeric(15,5)) *cast(SP_6_Glass as numeric(15,5)) *
		cast(SP_7_Glass as numeric(15,5)) *cast(SP_8_Glass as numeric(15,5)) *
		cast(SP_9_Glass as numeric(15,5)) *cast(SP_10_Glass as numeric(15,5)) *
		cast(SP_11_Glass as numeric(15,5)) *cast(SP_12_Glass as numeric(15,5)) * cast(SP_13_Glass as numeric(15,5)) as SP_Glass_Rel
 from CalibreSSiSdev.emula.OM_property_pre_3_temp_'+@suffix+'_'+@version+' a 
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''Alarm'',''LOCALMONITOR'',a.MonitoredBaseAlarmType,''Building'') g1
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''Alarm'',''LOCALMONITOR'',a.MonitoredBaseAlarmType,''CSO'') g2
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''Alarm'',''LOCALMONITOR'',a.MonitoredBaseAlarmType,''Peril'') g3
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''Alarm'',''LOCALMONITOR'',a.MonitoredBaseAlarmType,''Theft'') g4
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''Alarm'',''LOCALMONITOR'',a.MonitoredBaseAlarmType,''Money'') g5
),

temp4_'+@suffix+'_'+@version+' as (
select 
	a.*
	, (select max(comb_rel)
	 from ( values (a.Min_Rel_Max_Dis_SP_Building),(SP_Building_Rel)) b(comb_rel)
	 ) as comb_rel_building
	, (select max(comb_rel)
	 from ( values (a.Min_Rel_Max_Dis_SP_CSO),(SP_CSO_Rel)) b(comb_rel)
	 ) as comb_rel_cso
	, (select max(comb_rel)
	 from ( values (a.Min_Rel_Max_Dis_SP_Peril),(SP_Peril_Rel)) b(comb_rel)
	 ) as comb_rel_Peril
	, (select max(comb_rel)
	 from ( values (a.Min_Rel_Max_Dis_SP_Theft),(SP_Theft_Rel)) b(comb_rel)
	 ) as comb_rel_Theft
	, (select max(comb_rel)
	 from ( values (a.Min_Rel_Max_Dis_SP_Money),(SP_Money_Rel)) b(comb_rel)
	 ) as comb_rel_Money
	, (select max(comb_rel)
	 from ( values (a.Min_Rel_Max_Dis_SP_glass),(SP_Glass_Rel)) b(comb_rel)
	 ) as comb_rel_glass
 from temp3_'+@suffix+'_'+@version+' a
)
select 
	a.*
	, a.Alamr_Rel_Buildling * comb_rel_building * SP_Loading_Rel_Building as SP_Combind_Rel_Building
	, a.Alamr_Rel_CSO * comb_rel_cso * SP_Loading_Rel_cso as SP_Combind_Rel_cso
	, a.Alamr_Rel_peril * comb_rel_peril * SP_Loading_Rel_peril as SP_Combind_Rel_peril
	, comb_rel_theft * SP_Loading_Rel_theft as SP_Combind_Rel_theft
	, comb_rel_money * SP_Loading_Rel_money as SP_Combind_Rel_money
	, comb_rel_glass * SP_Loading_Rel_glass as SP_Combind_Rel_glass

	, Case When ((a.Category = ''Non_PO'' and a.OSQ107_Count is NULL) Or (a.Category = ''PO'' and OSQ107_Count in (NULL,0))) and a.Fire_Class < 8 Then Coalesce(Cast(j2.int_property_a as float),1) Else 1 End As SprayPainting_Rel
	, Case When ((a.Category = ''Non_PO'' and a.OSQ100_Count is NULL) Or (a.Category = ''PO'' and OSQ100_Count in (NULL,0))) and a.Fire_Class < 8 and Deepfryers in (''DEEPFRY'', ''BOTH'', ''WOK'') Then Coalesce(Cast(j3.int_property_a as float),1) Else 1 End As DeepFryers_Rel
	, Case When ((a.Category = ''Non_PO'' and a.OSQ112A_Count is NULL) Or (a.Category = ''PO'' and OSQ112B_Count in (NULL,0) and OSQ112A_Count > 0)) and a.DeepFryersOilVolume > 10 Then Coalesce(Cast(j4.int_property_a as float),1) Else 1 End As DeepFryersOilVolume_Rel
	, Case When ((a.Category = ''Non_PO'' and a.OSQ104_Count is NULL) Or (a.Category = ''PO'' and OSQ104_Count in (NULL,0))) and a.Fire_Class < 9 Then Coalesce(Cast(j5.int_property_a as float),1) Else 1 End As PlasticsMoulding_Rel
	, Coalesce(Cast(j6.int_property_a as float),1) As StorageHeight_Rel
	, Coalesce(Cast(j7.int_property_a as float),1) As ManufacturingPercentage_Rel
	, Coalesce(Cast(j8.int_property_a as float),1) As FibreGlassWork_Rel
	, Coalesce(Cast(j9.int_property_a as float),1) As WashFacility_Rel
	, Coalesce(Cast(j10.int_property_a as float),1) As RepairServicePremises_Rel
	, Case When ((a.Category = ''Non_PO'' and a.OSQ99_Count is NULL) Or (a.Category = ''PO'' and OSQ99_Count in (NULL,0))) and a.Fire_Class < 8 and (RestaurantorBar in (''REST'', ''BAR'', ''BOTH'')) Then Coalesce(Cast(j11.int_property_a as float),1) Else 1 End As RestaurantorBar_Rel
	, Case When ((a.Category = ''Non_PO'' and a.OSQ111_Count is NULL) Or (a.Category = ''PO'' and OSQ111_Count in (NULL,0))) and a.Fire_Class < 8 Then Coalesce(Cast(j12.int_property_a as float),1) Else 1 End As Woodworking_Rel
	, Coalesce(Cast(j13.int_property_a as float),1) As WoodworkingDustExtractorClean_Rel
	, Coalesce(Cast(j14.int_property_a as float),1) As SprayPaintingControl_Rel
	, Coalesce(Cast(j15.int_property_a as float),1) As WasteRemovalProcess_Rel
	, Coalesce(Cast(j16.int_property_a as float),1) As TimberStorageYard_Rel
	, Coalesce(Cast(j17.int_property_a as float),1) As StorageWarehouse_Rel
	, Coalesce(Cast(j18.int_property_a as float),1) As WoodworkingDustExtractors_Rel

into CalibreSSiSdev.emula.OM_property_pre_3_'+@suffix+'_'+@version+'
from temp4_'+@suffix+'_'+@version+' a
	 left join CalibreSSiSdev.dbo.ccomm_data_'+@suffix+'_'+@version+' j2 on UPPER(j2.code) = a.SprayPainting and j2.groupid = ''OSQ107'' and j2.Current_Flag = ''YES''------new row added in
	 left join CalibreSSiSdev.dbo.ccomm_data_'+@suffix+'_'+@version+' j3 on UPPER(j3.code) = a.DeepFryers and j3.groupid = ''OSQ100'' and j3.Current_Flag = ''YES''------new row added in
	 left join CalibreSSiSdev.dbo.ccomm_data_'+@suffix+'_'+@version+' j4 on UPPER(j4.code) = ''RATE'' and j4.groupid = ''OSQ112'' and j4.Current_Flag = ''YES'' ------new row added in
	 left join CalibreSSiSdev.dbo.ccomm_data_'+@suffix+'_'+@version+' j5 on UPPER(j5.code) = a.PlasticsMoulding and j5.groupid = ''OSQ104'' and j5.Current_Flag = ''YES''------new row added in
	 left join CalibreSSiSdev.dbo.ccomm_data_'+@suffix+'_'+@version+' j6 on UPPER(j6.code) = a.StorageHeight and j6.groupid = ''OSQ110'' and j6.Current_Flag = ''YES'' ------new row added in
	 left join CalibreSSiSdev.dbo.ccomm_data_'+@suffix+'_'+@version+' j7 on UPPER(j7.code) = a.ManufacturingPercentage and j7.groupid = ''OSQ11'' and j7.Current_Flag = ''YES'' and j7.version < 280------new row added in
	 left join CalibreSSiSdev.dbo.ccomm_data_'+@suffix+'_'+@version+' j8 on UPPER(j8.code) = a.FibreGlassWork and j8.groupid = ''OSQ26'' and j8.Current_Flag = ''YES'' and j8.version < 500------new row added in
	 left join CalibreSSiSdev.dbo.ccomm_data_'+@suffix+'_'+@version+' j9 on UPPER(j9.code) = a.WashFacility and j9.groupid = ''OSQ12.1'' and j9.Current_Flag = ''YES'' and j9.version < 285------new row added in
	 left join CalibreSSiSdev.dbo.ccomm_data_'+@suffix+'_'+@version+' j10 on UPPER(j10.code) = a.RepairServicePremises and j10.groupid = ''OSQ50'' and j10.Current_Flag = ''YES'' and j10.version < 500 ------new row added in
	 left join CalibreSSiSdev.dbo.ccomm_data_'+@suffix+'_'+@version+' j11 on UPPER(j11.code) = a.RestaurantorBar and j11.groupid = ''OSQ99'' and j11.Current_Flag = ''YES'' ------new row added in
	 left join CalibreSSiSdev.dbo.ccomm_data_'+@suffix+'_'+@version+' j12 on UPPER(j12.code) = a.Woodworking and j12.groupid = ''OSQ111'' and j12.Current_Flag = ''YES'' ------new row added in
	 left join CalibreSSiSdev.dbo.ccomm_data_'+@suffix+'_'+@version+' j13 on UPPER(j13.code) = a.WoodworkingDustExtractorCleaning and j13.groupid = ''OSQ97'' and j13.Current_Flag = ''YES'' ------new row added in
	 left join CalibreSSiSdev.dbo.ccomm_data_'+@suffix+'_'+@version+' j14 on UPPER(j14.code) = a.SprayPaintingControl and j14.groupid = ''OSQ94'' and j14.Current_Flag = ''YES'' ------new row added in
	 left join CalibreSSiSdev.dbo.ccomm_data_'+@suffix+'_'+@version+' j15 on UPPER(j15.code) = a.WasteRemovalProcess and j15.groupid = ''OSQ93'' and j15.Current_Flag = ''YES'' ------new row added in
	 left join CalibreSSiSdev.dbo.ccomm_data_'+@suffix+'_'+@version+' j16 on UPPER(j16.code) = a.TimberStorageYard and j16.groupid = ''OSQ32'' and j16.Current_Flag = ''YES'' and j16.version > 400 ------new row added in
	 left join CalibreSSiSdev.dbo.ccomm_data_'+@suffix+'_'+@version+' j17 on UPPER(j17.code) = a.StorageWarehouse and j17.groupid = ''OSQ35'' and j17.Current_Flag = ''YES'' and j17.version < 500------new row added in
	 left join CalibreSSiSdev.dbo.ccomm_data_'+@suffix+'_'+@version+' j18 on UPPER(j18.code) = a.WoodworkingDustExtractors and j18.groupid = ''OSQ97'' and j18.Current_Flag = ''YES'' ------new row added in

;'
;



------ ( 7 mins) ------------------------------------------------------------------------
---Town Water, Fire Bridage, ATM, Flammable Goods, Multi Building, EPS, Number of Stories,
-- Multi Situation, Liability Indemnity, Year Rewired, Fire Class, Multi Tenant, Heritage, Rewriting of Record,
-- Removal_of_Debris_FC, Playing_Surfaces_FC, Extra_Cost_Reinstatement_SI Rel
------------------------------------------------------------------------------

SET @PD_Emulation_Step8_A='
drop table if exists  CalibreSSiSdev.emula.OM_property_pre_4_temp_'+@suffix+'_'+@version+';

select 
	a.*
	, case when 
	 cast((coalesce(BuildingSumInsured,0) + coalesce(ContentsSumInsured,0) + coalesce(StockSumInsured,0)
		+coalesce(SpecifiedItemsSumInsured,0)) as numeric(15,2)) = 0 then 0
	 else 
	 round(a.LimitOfLiability/
	 cast((coalesce(BuildingSumInsured,0) + coalesce(ContentsSumInsured,0) + coalesce(StockSumInsured,0)
		+coalesce(SpecifiedItemsSumInsured,0)) as numeric(15,2)),2) 
		end as limit_of_liability_ratio
	, b1.value as TownWater_Rel_Building
	, b2.value as TownWater_Rel_CSO
	, b3.value as TownWater_Rel_Perils
	, Case When a.FireBrigade is not null then c1.value else ''1'' end as FireBridage_Rel_Building
	, Case When a.FireBrigade is not null then c2.value else ''1'' end  as FireBridage_Rel_CSO
	, Case When a.FireBrigade is not null then c3.value else ''1'' end  as FireBridage_Rel_Perils
	, case when a.atmonpremises is not null then d1.value 
		else ''1'' end as ATM_Building
	, case when a.atmonpremises is not null then d2.value 
		else ''1'' end as ATM_CSO
	, case when a.atmonpremises is not null then d3.value 
		else ''1'' end as ATM_Perils
	, case when a.Category = ''PO'' then ''1'' --add in 2022
		  when ee.code is not null then ''1'' --add in 2022: for occupations in StorageOfFlammableGoodsException
		  when a.HasFlammableGoods = ''YES''  then e1.value
		  else ''1'' end as Flammable_Goods_Building
	, case when a.Category = ''PO'' then ''1'' --add in 2022
		  when ee.code is not null then ''1''--add in 2022: for occupations in StorageOfFlammableGoodsException
		  when a.HasFlammableGoods = ''YES'' then e2.value 
		  else ''1'' end as Flammable_GoodS_CSO
	, case when a.Category = ''PO'' then ''1'' --add in 2022
		  when ee.code is not null then ''1''--add in 2022: for occupations in StorageOfFlammableGoodsException
		  when a.HasFlammableGoods = ''YES'' then e3.value 
		  else ''1'' end as Flammable_Goods_Peril
	, iif(ee.code is not null, ''Yes'', ''No'') as StorageOfFlammableGoodsException
	, coalesce(f1.value,1) as Multi_Building_Rel_Building
	, coalesce(f2.value,1) as Multi_Building_Rel_CSO
	, coalesce(f3.value,1) as Multi_Building_Rel_Peril
	, case when a.epsamount is null then ''1''
		else g1.value end as EPS_Building
	, case when a.epsamount is null then ''1''
		else g2.value end as EPS_CSO
	, case when a.epsamount is null then ''1''
		else g3.value end as EPS_Peril
	, case when a.NumberOfStories is null then ''1''
		else h1.value end as No_Stories_Rel_Building
	, case when a.NumberOfStories is null then ''1''
		else h2.value end as No_Stories_Rel_CSO
	, case when a.NumberOfStories is null then ''1''
		else h3.value end as No_Stories_Rel_Peril
	, i1.value as Multi_situation_Rel_Building
	, i2.value as Multi_situation_Rel_CSO
	, i3.value as Multi_situation_Rel_Peril

	, Case When Channel in (''CALIBRE_BUSINESS_PACK_PRODUCT'', ''BIZCOVER_BUSINESS_PACK_PRODUCT'') Then 1	
		When Channel = ''STEADFAST_BUSINESS_PACK_PRODUCT'' Then 
		SprayPainting_Rel * DeepFryers_Rel * DeepFryersOilVolume_Rel * PlasticsMoulding_Rel * StorageHeight_Rel * ManufacturingPercentage_Rel * FibreGlassWork_Rel * WashFacility_Rel * RepairServicePremises_Rel * RestaurantorBar_Rel * Woodworking_Rel * WoodworkingDustExtractorClean_Rel * SprayPaintingControl_Rel * WasteRemovalProcess_Rel * TimberStorageYard_Rel * StorageWarehouse_Rel * WoodworkingDustExtractors_Rel
		Else 1 End As Calliden_OSQ_Rel

'
;

SET @PD_Emulation_Step8_B='
into CalibreSSiSdev.emula.OM_property_pre_4_temp_'+@suffix+'_'+@version+'
from CalibreSSiSdev.emula.OM_property_pre_3_'+@suffix+'_'+@version+' a 

	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''TownWaterSupply'',coalesce(a.ConnectedTownWater,''YES''),'''',''Building'') b1
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''TownWaterSupply'',coalesce(a.ConnectedTownWater,''YES''),'''',''CSO'') b2
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''TownWaterSupply'',coalesce(a.ConnectedTownWater,''YES''),'''',''Peril'') b3
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''FireBrigade'',a.firebrigade,'''',''Building'') c1
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''FireBrigade'',a.firebrigade,'''',''CSO'') c2
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''FireBrigade'',a.firebrigade,'''',''Peril'') c3
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''ATM'',a.AtmOnPremises,'''',''Building'') d1
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''ATM'',a.AtmOnPremises,'''',''CSO'') d2
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''ATM'',a.AtmOnPremises,'''',''Peril'') d3
	outer apply CalibreSSiSdev.dbo.emula_SDP_BUSINESSPROPERTY_LOWER_UPPER3_final(''StorageOfFlammableGoods'','''','''',''Building'',a.FlammableGoodsQuantity) e1
	outer apply CalibreSSiSdev.dbo.emula_SDP_BUSINESSPROPERTY_LOWER_UPPER3_final(''StorageOfFlammableGoods'','''','''',''CSO'',a.FlammableGoodsQuantity) e2
	outer apply CalibreSSiSdev.dbo.emula_SDP_BUSINESSPROPERTY_LOWER_UPPER3_final(''StorageOfFlammableGoods'','''','''',''Peril'',a.FlammableGoodsQuantity) e3
	left join (select * from CalibreSSiSdev.dbo.ccomm_data_final
	 where groupid = ''StorageOfFlammableGoodsException'' and CURRENT_FLAG = ''YES'') ee --added in 2022
	 on a.ANZSIC collate database_default = ee.code 
		or a.Tenant1_Occ collate database_default = ee.code  
		or a.Tenant2_Occ collate database_default = ee.code  
		or a.Tenant3_Occ collate database_default = ee.code 
		or a.Tenant4_Occ collate database_default = ee.code 
		or a.Tenant5_Occ collate database_default = ee.code  
		or a.Tenant6_Occ collate database_default = ee.code 
		or a.Tenant7_Occ collate database_default = ee.code 
	 outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''MultipleBuildings'',a.HasMultipleBuildings,'''',''Building'') f1
	 outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''MultipleBuildings'',a.HasMultipleBuildings,'''',''CSO'') f2
	 outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''MultipleBuildings'',a.HasMultipleBuildings,'''',''Peril'') f3
	 outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''EPS'',a.EPSAmount,'''',''Building'') g1
	 outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''EPS'',a.EPSAmount,'''',''CSO'') g2
	 outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''EPS'',a.EPSAmount,'''',''Peril'') g3
	 outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_LOWER_UPPER_final(''NumberOfStories'','''','''',''Building'',a.NumberOfStories) h1
	 outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_LOWER_UPPER_final(''NumberOfStories'','''','''',''CSO'',a.NumberOfStories) h2
	 outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_LOWER_UPPER_final(''NumberOfStories'','''','''',''Peril'',a.NumberOfStories) h3
	 outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_LOWER_UPPER_final(''NoofLocations'','''',''NoofLocations'',''Building'',a.situation_count) i1
	 outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_LOWER_UPPER_final(''NoofLocations'','''',''NoofLocations'',''CSO'',a.situation_count) i2
	 outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_LOWER_UPPER_final(''NoofLocations'','''',''NoofLocations'',''Peril'',a.situation_count) i3



;'
;


SET @PD_Emulation_Step9='

drop table if exists  CalibreSSiSdev.emula.OM_property_pre_4_'+@suffix+'_'+@version+';
 
select 
	a.*
	, case when a.limit_of_liability_ratio is null then ''1''
		else b1.value end as Limit_of_Liability_Building
	, case when a.limit_of_liability_ratio is null then ''1''
		else b1.value end as Limit_of_Liability_CSO
	, case when a.YearRewired is null or a.YearRewired = 0 then ''1'' else c2.value end as Year_Rewired_Rel_CSO
	, case when a.YearRewired is null or a.YearRewired = 0 then ''1'' else c2.value end as Year_Rewired_Rel_CSO_byband--Karen add to match Core, but this is a bug (duplication as above)

	, iif(a.YearRewired is null or a.YearRewired = 0 , ''1'', c11.value) as Year_Rewired_Group_Rel_Building
 
	, Coalesce(Cast(Calliden_OSQ_Rel As VarChar), ''1'') as Calliden_OSQ_Rel_Building
	, Coalesce(Cast(Calliden_OSQ_Rel As VarChar), ''1'') as Calliden_OSQ_Rel_CSO

	, d1.fire_class as Tenant_1_Occ_FireClass
	, d2.fire_class as Tenant_2_Occ_FireClass
	, d3.fire_class as Tenant_3_Occ_FireClass
	, d4.fire_class as Tenant_4_Occ_FireClass
	, d5.fire_class as Tenant_5_Occ_FireClass
	, d6.fire_class as Tenant_6_Occ_FireClass
	, d7.fire_class as Tenant_7_Occ_FireClass

	, ''1'' as Multi_Tenanted_PO_HH_Building --comment out in
	, ''1'' as Multi_Tenanted_PO_HH_CSO --comment out in

	, Coalesce(e1.value,''1.09'') as Heritage_Rel_CSO
	, Coalesce(e2.value,''1'') as Heritage_Rel_building ----------------------new row added in 
	, ''1'' as Seasonal_Increase_CSO
	, (select max(max_rel)
	  from (values (cast(a.RewritingRecordsSumInsured as numeric(15,5)) - cast(f1.value as numeric(15,5)) ),
		   (0)) b(max_rel)) as Rewriting_of_Records_FC
	, case when (select min(min_rel)
	   from  (values (cast(a.debrissuminsured as numeric(15,5)) - 
					0.2* (coalesce(cast(a.BuildingSumInsured as numeric(15,5)),0) + coalesce(cast(a.ContentsSumInsured as numeric(15,5)),0))),
				  (cast(a.debrissuminsured as numeric(15,5)) - cast(f2.value as numeric(15,5)))
				  ) b(min_rel)) < 0 then 0 else 
			(select min(min_rel)
	   from  (values (cast(a.debrissuminsured as numeric(15,5)) - 
					0.2* (coalesce(cast(a.BuildingSumInsured as numeric(15,5)),0) + coalesce(cast(a.ContentsSumInsured as numeric(15,5)),0))),
				  (cast(a.debrissuminsured as numeric(15,5)) - cast(f2.value as numeric(15,5)))
				  ) b(min_rel)) end 
				  as Removal_of_Debris_FC
	, (select max(max_rel)
	 from ( values (
		 cast(a.PlayingSurfacesSumInsured as numeric(15,5)) - cast(f3.value as numeric(15,5))),
		 (0)) b(max_rel)) as Playing_Surfaces_FC
	, a.ExtraCostSumInsured as Extra_Cost_Reinstatement_SI
	, case when a.StrataMortgageeInterestOnly = ''Yes'' then g.value else ''1'' end as Strata_Title

 
	, iif( a.PROPERTY_SECTION_TAKEN = 1 and a.total_section = 1 , ''Yes'', ''No'') as FireOnly
 
	, ''1'' as FireOnly_Rel_building --comment out in
	, ''1'' as FireOnly_Rel_CSO --comment out in


into CalibreSSiSdev.emula.OM_property_pre_4_'+@suffix+'_'+@version+'
from CalibreSSiSdev.emula.OM_property_pre_4_temp_'+@suffix+'_'+@version+' a 
	outer apply CalibreSSiSdev.dbo.emula_SDP_BUSINESSPROPERTY_LOWER_UPPER2_final(''LimitofLiability'','''','''','''',a.limit_of_liability_ratio) b1
	outer apply CalibreSSiSdev.dbo.emula_SDP_BUSINESSPROPERTY_LOWER_UPPER_final(''RewiredAge'','''','''',''CSO'',a.RewiredAge) c2
	outer apply CalibreSSiSdev.dbo.emula_SDP_BUSINESSPROPERTY_LOWER_UPPER_final(''RewiredYear'','''','''',''Building'',a.YearRewired) c11
	outer apply CalibreSSiSdev.dbo.emula_SDP_BUSINESSPROPERTY_LOWER_UPPER_final(''RewiredYear'','''','''',''CSO'',a.YearRewired) c22

	left join CalibreSSiSdev.dbo.ccomm_occupation_final d1
		on a.Tenant1_Occ = cast(d1.calliden_code as varchar) collate SQL_Latin1_General_CP1_CI_AS
		and d1.CURRENT_FLAG = ''YES'' 
	left join CalibreSSiSdev.dbo.ccomm_occupation_final d2
		on a.Tenant2_Occ = cast(d2.calliden_code as varchar) collate SQL_Latin1_General_CP1_CI_AS
		and d2.CURRENT_FLAG = ''YES'' 
	left join CalibreSSiSdev.dbo.ccomm_occupation_final d3
		on a.Tenant3_Occ =cast( d3.calliden_code as varchar) collate SQL_Latin1_General_CP1_CI_AS
		and d3.CURRENT_FLAG = ''YES''
	left join CalibreSSiSdev.dbo.ccomm_occupation_final d4
		on a.Tenant4_Occ = cast(d4.calliden_code as varchar) collate SQL_Latin1_General_CP1_CI_AS
		and d4.CURRENT_FLAG = ''YES'' 
	left join CalibreSSiSdev.dbo.ccomm_occupation_final d5 
		on a.Tenant5_Occ = cast(d5.calliden_code as varchar) collate SQL_Latin1_General_CP1_CI_AS
		and d5.CURRENT_FLAG = ''YES''
	left join CalibreSSiSdev.dbo.ccomm_occupation_final d6
		on a.Tenant6_Occ = cast(d6.calliden_code as varchar) collate SQL_Latin1_General_CP1_CI_AS
		and d6.CURRENT_FLAG = ''YES''
	left join CalibreSSiSdev.dbo.ccomm_occupation_final d7
		on a.Tenant7_Occ =cast( d7.calliden_code as varchar) collate SQL_Latin1_General_CP1_CI_AS
		and d7.CURRENT_FLAG = ''YES''

	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_LOWER_UPPER2_final(''MultiTenantHighHazard'','''','''','''',cast(a.tenant_count as numeric(15,5))) de
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''HeritageListed'',a.IsHeritageListed,'''',''CSO'') e1
	outer apply CalibreSSiSdev.dbo.EMULA_SDP_BUSINESSPROPERTY_final(''HeritageListedBuilding'',a.IsHeritageListed,'''',''Building'') e2 ------new row added in
	left join CalibreSSiSdev.dbo.ccomm_freecovers_final  f1
		on f1.section = ''Fire'' and f1.covertype = ''Rewriting of Records'' and f1.CURRENT_FLAG = ''YES'' 
		and ( (a.Channel <> ''STEADFAST_BUSINESS_PACK_PRODUCT'' and f1.product = a.Channel collate SQL_Latin1_General_CP1_CI_AS) or (a.Channel = ''STEADFAST_BUSINESS_PACK_PRODUCT'' and f1.product is NULL))
	left join CalibreSSiSdev.dbo.ccomm_freecovers_final  f2
		on f2.section = ''Fire'' and f2.covertype = ''Removal of Debris'' and f2.CURRENT_FLAG = ''YES'' 
	left join CalibreSSiSdev.dbo.ccomm_freecovers_final  f3
		on f3.section = ''Fire'' and f3.covertype = ''Playing Surfaces'' and f3.CURRENT_FLAG = ''YES'' 
	outer apply CalibreSSiSdev.dbo.emula_SDP_BUSINESSPROPERTY_LOWER_UPPER2_final(''StrataSI'','''','''','''',cast(a.BuildingSumInsured as numeric(15,5))) g

	left join CalibreSSiSdev.dbo.ccomm_businessproperty_final h1 --added in
		on h1.groupid = ''FireOnly'' and h1.relativitytype = ''Building''
		and h1.CURRENT_FLAG = ''YES''
	left join CalibreSSiSdev.dbo.ccomm_businessproperty_final h2 --added in
		on h2.groupid = ''FireOnly'' and h2.relativitytype = ''CSO''
		and h2.CURRENT_FLAG = ''YES''
;'
;


-----------------------------------------------------------------
---- Calculate the final Prem (10 mins)
-----------------------------------------------------------------

SET @PD_Emulation_Step10_A='

drop table if exists  CalibreSSiSdev.emula.OM_property_premium_'+@suffix+'_'+@version+';

with temp5_Final as (
select 
	a.* 
	, a.Building_Contents_Base_Rate * a.Occupation_Building_Rel * a.Suburb_Building_Rel * 
		a.Wall_Building_Rel * a.Roof_Building_Rel * a.Floor_Building_Rel * a.Fire_Protection_Combined_Building * 
		a.Building_Age_Building_Rel * a.Locality_Building_Rel * a.Multi_situation_Rel_Building * 
		a.Total_SI_Building_Rel *  a.Excess_Building_Rel * a.PO_Building_Rel *  a.SP_Combind_Rel_Building *
		a.TownWater_Rel_Building * coalesce(cast(a.FireBridage_Rel_Building as numeric(15,5)),1) * 
		a.ATM_Building * a.Flammable_Goods_Building * a.Calliden_OSQ_Rel_Building * 
		a.Multi_Building_Rel_Building * a.EPS_Building *  a.No_Stories_Rel_Building *  a.Limit_of_Liability_Building 
		*cast(a.Year_Rewired_Group_Rel_Building as numeric(15,5))
		* a.Heritage_Rel_building * a.FireOnly_Rel_building -- added in 2022
		* a.floodloading--added in 2022
	as Final_Building_Rate

	, a.Building_Contents_Base_Rate * a.Occupation_CSO_Rel *  a.Suburb_CSO_Rel * a.Wall_CSO_Rel * a.Roof_CSO_Rel *
		a.Floor_CSO_Rel *a.Fire_Protection_Combined_CSO *a.Building_Age_CSO_Rel *a.Locality_CSO_Rel *a.Multi_situation_Rel_CSO * 
		a.Total_SI_CSO_Rel * a.Excess_CSO_Rel * a.PO_CSO_Rel * a.SP_Combind_Rel_cso *a.TownWater_Rel_CSO *
		coalesce(cast(a.FireBridage_Rel_CSO as numeric(15,5)),1) * a.ATM_CSO * a.Flammable_GoodS_CSO *  a.Calliden_OSQ_Rel_CSO * 
		a.Multi_Building_Rel_Building * 
		a.EPS_CSO * a.No_Stories_Rel_CSO * a.Limit_of_Liability_CSO
		*Year_Rewired_Rel_CSO * Year_Rewired_Rel_CSO_byband 
		* a.Heritage_Rel_CSO * a.FireOnly_Rel_CSO --added in 2022
		* a.floodloading--added in 2022
	as Final_CSO_Rate

	, a.peril_Base_Rate* a.Suburb_Peril_Rel *a.Wall_Peril_Rel * a.Roof_Peril_Rel * a.Floor_Peril_Rel * a.Fire_Protection_Combined_Peril * 
		a.Building_Age_Peril_Rel *  a.Locality_Peril_Rel * a.Multi_situation_Rel_Peril * a.Total_SI_Peril_Rel * 
		a.Excess_Peril_Rel * a.PO_Peril_Rel * 
		a.TownWater_Rel_Perils * coalesce(cast(a.FireBridage_Rel_Perils as numeric(15,5)),1) * a.Multi_Building_Rel_Peril * 
		a.EPS_Peril * a.No_Stories_Rel_Peril  
		* a.floodloading--added in 2022
	as Final_Peril_Rate
	, b.value as MultiSectionDiscount
from CalibreSSiSdev.emula.OM_property_pre_4_'+@suffix+'_'+@version+' a
	outer apply CalibreSSiSdev.dbo.emula_SDP_DATA_LOWER_UPPER_final(''MultiSectionDiscount'','''', total_section) b
),

';

SET @PD_Emulation_Step10_B='
temp6_Final as (
	select 
	a.*
	, (select max(max_rate)
	 from (values (a.Final_Building_Rate + a.Final_Peril_Rate), (cast(b.value as numeric(15,5))))
	 b(max_rate)
	) as Final_Final_Building_Rate
	, (select max(max_rate)
	 from (values (a.Final_CSO_Rate + a.Final_Peril_Rate), (cast(b.value as numeric(15,5))))
	 b(max_rate)
	) as Final_Final_Contents_Rate
	, cast(b.value as numeric(15,5)) as Minimum_Rate

From temp5_Final a 
	left join CalibreSSiSdev.dbo.ccomm_minimum_final b
		on b.section = ''Fire'' and type = ''Minimum_Rate'' and CURRENT_FLAG = ''YES''
),
temp7_Final as (
select 
	a.*
	, case when a.StrataMortgageeInterestOnly = ''Yes'' then ''0''
		else coalesce(a.Final_Building_Rate * buildingsuminsured * a.multisectiondiscount,0) end as Building_Fire_Premium
	, case when a.StrataMortgageeInterestOnly = ''Yes'' then ''0''
		else coalesce(a.Final_Peril_Rate * buildingsuminsured * a.multisectiondiscount,0) end as Building_Peril_Premium
	, case when a.StrataMortgageeInterestOnly = ''Yes'' then ''0''
		else coalesce(Final_Final_Building_Rate * buildingsuminsured * a.multisectiondiscount,0) end as Building_Premium

	, coalesce(a.Final_CSO_Rate * contentssuminsured * a.multisectiondiscount,0) as Contents_Fire_Premium
	, coalesce(a.Final_Peril_Rate * contentssuminsured * a.multisectiondiscount,0) as Contents_Peril_Premium
	, coalesce(Final_Final_Contents_Rate * contentssuminsured * a.multisectiondiscount,0) as Contents_Premium

	, coalesce(a.Final_CSO_Rate * stocksuminsured * a.multisectiondiscount,0) as Stock_Fire_Premium
	, coalesce(a.Final_Peril_Rate * stocksuminsured * a.multisectiondiscount,0) as Stock_Peril_Premium
	, coalesce(Final_Final_Contents_Rate * stocksuminsured * a.multisectiondiscount,0) as Stock_Premium

	, coalesce(a.Final_CSO_Rate * SpecifiedItemsSumInsured * a.multisectiondiscount,0) as Speicified_Items_Fire_Premium
	, coalesce(a.Final_Peril_Rate * SpecifiedItemsSumInsured * a.multisectiondiscount,0) as Speicified_Items_Peril_Premium
	, coalesce(Final_Final_Contents_Rate * coalesce(SpecifiedItemsSumInsured,0) * a.multisectiondiscount,0) as Speicified_Items_Premium


	, coalesce(a.Final_CSO_Rate * contentssuminsured * a.multisectiondiscount,0)+coalesce(a.Final_CSO_Rate * stocksuminsured * a.multisectiondiscount,0)+
		coalesce(a.Final_CSO_Rate * SpecifiedItemsSumInsured * a.multisectiondiscount,0) as Cts_Stock_SpecifiedItem_Fire_Prem

	, coalesce(a.Final_Peril_Rate * contentssuminsured * a.multisectiondiscount,0) + coalesce(a.Final_Peril_Rate * stocksuminsured * a.multisectiondiscount,0) +
		coalesce(a.Final_Peril_Rate * SpecifiedItemsSumInsured * a.multisectiondiscount,0) as Cts_Stock_SpecifiedItem_Peril_Prem
	, coalesce(Final_Final_Contents_Rate * contentssuminsured * a.multisectiondiscount,0) +  coalesce(Final_Final_Contents_Rate * stocksuminsured * a.multisectiondiscount,0) +
		coalesce(Final_Final_Contents_Rate * coalesce(SpecifiedItemsSumInsured,0) * a.multisectiondiscount,0) as Cts_Stock_SpecifiedItem_Prem

	, case when a.StrataMortgageeInterestOnly = ''Yes'' 
			then a.BuildingSumInsured * a.Final_Final_Building_Rate * a.Strata_Title * a.multisectiondiscount 
		 else ''0'' end Strata_Title_Premium
 from temp6_Final a
),
temp8_Final as (
	select 
	a.*
	, (coalesce(a.Building_Premium,0) + coalesce(a.Contents_Premium,0) + coalesce(a.Stock_Premium,0) + 
			coalesce(a.Speicified_Items_Premium,0) + 
			coalesce(a.Strata_Title_Premium,0)) /
			nullif((coalesce(a.BuildingSumInsured,0) + coalesce(a.ContentsSumInsured,0) + coalesce(a.StockSumInsured,0) +coalesce(a.SpecifiedItemsSumInsured,0) ),0) 
			as Weighted_Avg_Rate_for_PD
	from temp7_Final a),
temp9_Final as (
	select 
	a.* 
	, coalesce(a.Rewriting_of_Records_FC * Weighted_Avg_Rate_for_PD * a.multisectiondiscount,0) as Rewriting_Records_Premium
	, coalesce(a.Removal_of_Debris_FC * Weighted_Avg_Rate_for_PD * a.multisectiondiscount,0) as Removal_of_Debris_Premium
	, coalesce(a.ExtraCostSumInsured * Weighted_Avg_Rate_for_PD * a.multisectiondiscount,0) as Extra_Cost_of_Reinstatement_Premium
	, coalesce(a.Playing_Surfaces_FC *  Weighted_Avg_Rate_for_PD * a.multisectiondiscount,0) as Play_Surfaces_Premium

	from temp8_Final a
)
select 
	a.*
	, a.Building_Premium + a.Contents_Premium + a.Stock_Premium
		+ a.Speicified_Items_Premium 
		+ a.Strata_Title_Premium + a.Rewriting_Records_Premium 
		+ a.Removal_of_Debris_Premium 
		+ a.Extra_Cost_of_Reinstatement_Premium + a.Play_Surfaces_Premium as Sum_of_Premiums

	,	(select max(max_premium)
		from 
		(values
		((a.Building_Premium + a.Contents_Premium + a.Stock_Premium
			+ a.Speicified_Items_Premium 
			+ a.Strata_Title_Premium + a.Rewriting_Records_Premium 
			+ a.Removal_of_Debris_Premium 
			+ a.Extra_Cost_of_Reinstatement_Premium + a.Play_Surfaces_Premium
			) * 1
			)
			, (b.value)) as c(max_premium)
		) 
		* a.claimLoading* a.CLLoading* a.CL01Loding_prpOnly * a.DDLoading  * a.SSLoading* a.PNLoading--added in 2022
		 as Total_Property_Premium

	, b.value as Minimum_Premium
into CalibreSSiSdev.emula.OM_property_premium_'+@suffix+'_'+@version+'
from temp9_Final  a
	left join CalibreSSiSdev.dbo.ccomm_minimum_final b
		on b.section = ''Fire'' and b.type = ''Minimum_Premium'' and b.CURRENT_FLAG = ''YES'';

';

EXEC( @PD_Emulation_Step1 + @PD_Emulation_Step2 + @PD_Emulation_Step3_A + @PD_Emulation_Step3_B + @PD_Emulation_Step4_A + @PD_Emulation_Step4_B + @PD_Emulation_Step4_C + @PD_Emulation_Step4_D + @PD_Emulation_Step5 + @PD_Emulation_Step6 + @PD_Emulation_Step7_A + @PD_Emulation_Step7_B + @PD_Emulation_Step7_C + @PD_Emulation_Step7_D + @PD_Emulation_Step7_E + @PD_Emulation_Step8_A + @PD_Emulation_Step8_B + @PD_Emulation_Step9 + @PD_Emulation_Step10_A + @PD_Emulation_Step10_B);

END
GO


