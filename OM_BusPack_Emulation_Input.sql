USE [CalibreSSiSdev]
GO

/****** Object:  StoredProcedure [emula].[OM_BusPack_Emulation_Input_Test]    Script Date: 4/06/2024 5:51:16 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






CREATE procedure [emula].[OM_BusPack_Emulation_Input_Test] 
( @suffix varchar(99),
	@pid varchar(15),
	@versionno varchar(99)

) AS
BEGIN
		
											----------------------------------------------
											--				INITIALISATION				--
											----------------------------------------------

DECLARE
-- Step 1: Get Claims Loading and Summary of Claims 
  @Input_Emulation_Step1 NVARCHAR(MAX)
, @Input_Emulation_Step2 NVARCHAR(MAX)
, @Input_Emulation_Step3 NVARCHAR(MAX)
;



------------------------------------------
--	CLAIMS INPUTS: LOADING and SUMMARY	--
------------------------------------------

SET @Input_Emulation_Step1='
------------------------------
--		CLAIMS LOADING		--
------------------------------

drop table if exists  #claim_loading;
with temp as (
	select
		a.*
		, q.policy_number
		, q.TERM_START_DATE
		, q.stage_code 
		, q.Channel
		, q.nb_rn
	From CalibreSSiSdev.svu.s_clm_all_final a
		Left Join (select distinct POLICY_ID, policy_number, stage_code, TERM_START_DATE, term_end_date 
			, Case When Policy_Number like ''GA7%'' Then ''STEADFAST_BUSINESS_PACK_PRODUCT''
			When Policy_Wording_Ref in (''BIZCOVER_STANDARD'',''EXPRESS_COVER'') Then ''BIZCOVER_BUSINESS_PACK_PRODUCT'' 
			When Policy_Wording_Ref in (''CALIBRE_BUSPACK_STANDARD'') Then ''CALIBRE_BUSINESS_PACK_PRODUCT''
			Else NULL End As Channel, nb_rn
			from CalibreSSiSdev.svu.svu_analysis) q
			On a.Policy_ID = q.Policy_ID
), #CL01 as (
	select distinct policy_id, count(distinct concat(ClaimNumber, LossDate)) as clm_cnt_last1Y
	From temp
		where LossDate >= DATEADD(year, -1,TERM_START_DATE) AND Section <> ''BI''
			group by policy_id
), #CLLoading_0205 as ( 
	select distinct policy_number, TERM_START_DATE, policy_id, stage_code, Channel, nb_rn, count(distinct concat(ClaimNumber, LossDate)) as clm_cnt_total, sum(coalesce(cast(LossIncurred as numeric),0)) as inc_sum_total
	from temp
		group by policy_number, TERM_START_DATE, policy_id, stage_code, Channel, nb_rn
), #CLLoading_0304 as (
	select distinct policy_id, count(distinct concat(ClaimNumber, LossDate)) as clm_cnt_last2Y_nonBI, sum(coalesce(cast(LossIncurred as numeric),0)) as inc_sum_last2Y_nonBI
	from temp
		where LossDate >= DATEADD(year, -2,TERM_START_DATE) AND Section <> ''BI''
		group by policy_id
), #CLLoading_04 as (
	select distinct policy_id, count(distinct concat(ClaimNumber, LossDate)) as clm_cnt_last2Y, sum(coalesce(cast(LossIncurred as numeric),0)) as inc_sum_last2Y
	from temp
		where LossDate >= DATEADD(year, -2,TERM_START_DATE) 
		group by policy_id
), #CLLoading_05 as (
	select distinct policy_id, count(distinct concat(ClaimNumber, LossDate)) as clm_cnt_nonBI_LIA, sum(coalesce(cast(LossIncurred as numeric),0)) as inc_sum_nonBI_LIA
	from temp
		where Section not in (''BI'', ''LIAB'')
		group by policy_id
), #CLLoading_06 as (
	select distinct policy_id, count(distinct concat(ClaimNumber, LossDate)) as clm_cnt_postincep, sum(coalesce(cast(LossIncurred as numeric),0)) as inc_sum_postincep
	from temp
		where LossDate > DATEADD(year, -1,TERM_START_DATE) and Section not in (''BI'')
		group by policy_id
), #CLLoading_11 As (
	select distinct policy_id, count(distinct concat(ClaimNumber, LossDate)) as clm_cnt_14mths, sum(coalesce(cast(LossIncurred as numeric),0)) as inc_sum_14mths
	from temp
		where (LossDate <= DATEADD(month, 14,Cast(ReportedDate As date)) Or LossDate = ReportedDate) and Section = (''LIAB'')
		group by policy_id
), #claimLoading as (
	select distinct policy_id, count(distinct concat(ClaimNumber, LossDate)) as clm_cnt_nonBI, sum(coalesce(cast(LossIncurred as numeric),0))  as inc_sum
	from CalibreSSiSdev.svu.s_clm_all_final
		where Section <> ''BI''
		group by policy_id
), #CLLoading as (
select 
a.*
, b.clm_cnt_last1Y
, c.inc_sum_last2Y_nonBI
, d.inc_sum_last2Y
, case when (('+@versionno+' < 15 and h.clm_cnt_nonBI > 3) Or ('+@versionno+' > 15 and h.clm_cnt_nonBI > 2) ) And a.Channel <> ''CALIBRE_BUSINESS_PACK_PRODUCT'' 
		and a.stage_code in (''NEWBUSINESS'', ''QUOTE'',''NBAMEND'') then ''Yes''
	   when (('+@versionno+' >= 15 and '+@versionno+' < 30 and inc_sum_last2Y_nonBI > 5000) Or ('+@versionno+' < 15 and inc_sum_last2Y_nonBI > 10000) Or ('+@versionno+' >= 330 and inc_sum_last2Y_nonBI > 10000)) 
	   and a.stage_code not in (''RNTAKEUP'', ''TAKEUP'',''NBAMEND'')  then ''Yes''
	   when '+@versionno+' > 330 and e.inc_sum_nonBI_LIA > 10000 and a.Channel <>  ''CALIBRE_BUSINESS_PACK_PRODUCT'' then ''Yes''
	   when '+@versionno+' > 10 and a.stage_code in (''ALTERATION'', ''RENEWAL'') and clm_cnt_14mths>0 and a.Channel <> ''CALIBRE_BUSINESS_PACK_PRODUCT'' Then ''Yes''
	   when '+@versionno+' > 590 and a.stage_code in (''NEWBUSINESS'') and  inc_sum_14mths > 10000 and a.Channel <> ''CALIBRE_BUSINESS_PACK_PRODUCT''  Then ''Yes''
	   when (('+@versionno+' < 385 and inc_sum_total > 3000) Or ('+@versionno+' >= 285 and d.inc_sum_last2Y > 5000) Or ('+@versionno+' >= 330 and d.inc_sum_last2Y > 10000)) and a.Channel <> ''CALIBRE_BUSINESS_PACK_PRODUCT'' and a.stage_code not in (''RNTAKEUP'', ''TAKEUP'') Then ''Yes''
	   else ''No'' end as  CLLoading_flag
, iif(a.stage_code = ''NEWBUSINESS'' 
		and b.clm_cnt_last1Y >= 3
		and h.policy_id is not null, ''Yes'', ''No'') as CL01Loding_prpOnly_flag
, case when (h.clm_cnt_nonBI > 0 and '+@versionno+' >= 800) Or (clm_cnt_total>0 and '+@versionno+' >= 720 and '+@versionno+' < 800 and nb_rn = ''NB'') and (clm_cnt_total>0 and '+@versionno+' >= 540 and '+@versionno+' < 720) Then 1
	else 0 End as claimloading_flag_temp

from #CLLoading_0205 a
	left join #CL01		      b on a.policy_id = b.policy_id
	left join #CLLoading_0304 c on a.policy_id = c.policy_id
	left join #CLLoading_04   d on a.policy_id = d.policy_id
	left join #CLLoading_05   e on a.policy_id = e.policy_id
	left join #CLLoading_06   f on a.policy_id = f.policy_id
	left join #CLLoading_11   g on a.policy_id = g.policy_id
	left join #claimLoading   h on a.policy_id = h.policy_id
) 
Select 
a.*
, d.clm_cnt_nonBI
, iif(CLLoading_flag = ''No'' and claimloading_flag_temp = 1, ''Yes'', ''No'') as claimLoading_flag
into #claim_loading
From #CLLoading a
	left join #claimLoading   d on a.policy_id = d.policy_id


--------------------------------------
--	 Claims Details: Incurred		--
--------------------------------------

drop table if exists  CalibreSSiSdev.svu.s_clm_all_final_testingTool; 
select distinct policy_id, claimnumber, LossDate, LossDescription, section, sum(coalesce(cast(lossincurred as numeric),0)) as inc 
, row_number() over (partition by policy_id order by sum(coalesce(cast(lossincurred as numeric),0)) desc) as claim_no
into CalibreSSiSdev.svu.s_clm_all_final_testingTool
from CalibreSSiSdev.svu.s_clm_all_final
	group by policy_id, claimnumber, section, LossDate, LossDescription
;'
;



-------------------------------------------
--	 BASE TABLE WITH ALL RATING FACTORS	 --
-------------------------------------------

SET @Input_Emulation_Step2='

drop table if exists  CalibreSSiSdev.emula.testing_input_temp1_'+@suffix+';
with 
#ccomm_data_loading as ( 
	select * from Core_Reference_Data.dbo.ccomm_data_final 
		where CURRENT_FLAG = ''YES'' and (groupid like ''%Loading'' or groupid = ''flood'')
), InforceBook as 
(
Select
* 
, Dense_Rank() Over (Partition By svu_anal.policy_number, svu_anal.address_ref, svu_anal.term_start_date Order By svu_anal.modified_date DESC) As LatestTransTerm
From CalibreSSiSdev.svu.svu_analysis svu_anal
	Where svu_anal.Term_End_Date > '''+@pid+''' 
			And svu_anal.Term_Start_Date <= '''+@pid+'''
			And svu_anal.Status_Code in (''ONRISK'',''ONRISKFIN'',''OFFRISK'', ''SRLAPSED'')
			And svu_anal.Mode_Code in (''FINALISED'')
			And (svu_anal.Policy_Number like ''GA7%'' Or svu_anal.Policy_Wording_Ref in (''BIZCOVER_STANDARD'',''EXPRESS_COVER'',''CALIBRE_BUSPACK_STANDARD'') )
)
select
a.policy_id
, a.address_id
, Case When svu_anal.Policy_Number like ''GA7%'' Then ''STEADFAST_BUSINESS_PACK_PRODUCT''
	When svu_anal.Policy_Wording_Ref in (''BIZCOVER_STANDARD'',''EXPRESS_COVER'') Then ''BIZCOVER_BUSINESS_PACK_PRODUCT'' 
	When svu_anal.Policy_Wording_Ref in (''CALIBRE_BUSPACK_STANDARD'') Then ''CALIBRE_BUSINESS_PACK_PRODUCT''
	Else NULL End As Channel

, svu_anal.policy_number
, svu_anal.address_ref
, svu_anal.TERM_START_DATE
, svu_anal.TERM_END_DATe
, svu_anal.inception_date
, svu_anal.Broad_Occupation_Group
, svu_anal.metrocountry
, svu_anal.STAGE_CODE
, svu_anal.status_code
, svu_anal.insured_company_name
, svu_anal.anzsic_desc
, svu_anal.broker_account
, svu_anal.transaction_effective_date

--------------------------------------
--		PROPERTY RATING FACTORS		--
--------------------------------------

, a0.Tenant1_Occ as Tenant1_Occ
, a0.Tenant2_Occ as Tenant2_Occ
, a0.Tenant3_Occ as Tenant3_Occ
, a0.Tenant4_Occ as Tenant4_Occ
, a0.Tenant5_Occ as Tenant5_Occ
, a0.Tenant6_Occ as Tenant6_Occ
, a0.Tenant7_Occ as Tenant7_Occ

, b.SUBURB
, case when b.STATE is not null then b.State else b2.state end as state
, b.PCODE
, a.ANZSIC
, case when a.Category =''Property Owner'' or a.Category =''PropertyOwner'' then ''PO'' 
	else ''Non_PO'' end as Category
, a.Category as Category_ori
, a.AnnualTurnover
, a.TotalFullTimeStaff
, a.TotalPartTimeStaff
, a.HasMultipleBuildings
, a.YearBuilt
, a.YearRewired
, a.EpsAmount
, a.NumberOfStories
, a.FloorConstruction
, a.WallConstruction
, a.RoofConstruction
, case when ac.NONE = 1 then ''NONE'' else NULL end as Fire_Protection_0
, case when ac.EXTING  = 1 then ''EXTING'' else NULL end as Fire_Protection_1
, case when ac.REELS  = 1 then  ''REELS'' else NULL end as Fire_Protection_2
, case when ac.SPRINK  = 1 then  ''SPRINK'' else NULL end as Fire_Protection_3
, case when ac.SMOKEMON  = 1 then ''SMOKEMON'' else NULL end as Fire_Protection_4
, case when ac.SMOKEUNMON = 1 then  ''SMOKEUNMON'' else NULL end as Fire_Protection_5
, case when ac.HEATDET  = 1 then  ''HEATDET'' else NULL end as Fire_Protection_6
, case when ac.FIREALARM  = 1 then ''FIREALARM'' else NULL end as Fire_Protection_7
, case when ac.BASEALARM = 1 then  ''BASEALARM'' else NULL end as Fire_Protection_8
, case when ac.BLANKETS  = 1 then  ''BLANKETS'' else NULL end as Fire_Protection_9
, case when ac.FullSprinklerCoverage  = ''YES'' then ''FullSprinklerCoverage'' else NULL end as Fire_Protection_10
, case when ac.SprinklerStandards = ''YES'' then  ''SprinklerStandards'' else NULL end as Fire_Protection_11
, a.PercentSprinklerCoverage
, a.SprinklerWaterType
, case when ac.SPRINK  = 1 then ''Yes'' else ''No'' end as SprinklerStandards
, case when ad.NONE = 1 then ''NONE'' end as Security_Protection_0
, case when ad.LOCALALARM = 1 then ''LOCALALARM'' end as Security_Protection_1
, case when ad.BASEALARM = 1 then ''BASEALARM'' end as Security_Protection_2
, case when ad.WINDOWBARS = 1 then ''WINDOWBARS'' end as Security_Protection_3
, case when ad.WINDOWLOCKS = 1 then ''WINDOWLOCKS'' end as Security_Protection_4
, case when ad.DEADLOCKS = 1 then ''DEADLOCKS'' end as Security_Protection_5
, case when ad.DISPLAYWINDOW = 1 then ''DISPLAYWINDOW'' end as Security_Protection_6
, case when ad.LIGHTS = 1 then ''LIGHTS'' end as Security_Protection_7
, case when ad.BOLLARDS = 1 then ''BOLLARDS'' end as Security_Protection_8
, case when ad.CCTV= 1 then ''CCTV'' end as Security_Protection_9
, case when ad.FENCING = 1 then ''FENCING'' end as Security_Protection_10
, case when ad.PATROLS = 1 then ''PATROLS'' end as Security_Protection_11
, case when ad.KEYPAD = 1 then ''KEYPAD'' end as Security_Protection_12
, case when ad.SHUTTERS = 1 then ''SHUTTERS'' end as Security_Protection_13
, a.MonitoredBaseAlarmType
, a.AtmOnPremises
, a.LocationType
, a.ConnectedTownWater
, a.FireBrigade
, a.HasFlammableGoods
, a.FlammableGoodsQuantity
, a.HasSeasonalIncrease
, aa.seasonalincreasestart_1
, aa.seasonalincreaseend_1
, aa.seasonalincreasestart_2
, aa.seasonalincreaseend_2
, c.LimitOfliability
, c.PropertyExcess
, c.Has50PercentVacancy
, c.IsHeritageListed
, c.IsMultiTenant
, c.StrataMortgageeInterestOnly
, coalesce(c.BuildingSumInsured,0) as BuildingSumInsured
, coalesce(c.ContentsSumInsured,0) as ContentsSumInsured
, coalesce(c.StockSumInsured,0) as StockSumInsured
, coalesce(c.ExtraCostSumInsured,0) as ExtraCostSumInsured
, coalesce(c.DebrisSumInsured,0) as DebrisSumInsured
, coalesce(c.RewritingRecordsSumInsured,0) as RewritingRecordsSumInsured
, coalesce(c.PlayingSurfacesSumInsured,0) as PlayingSurfacesSumInsured
, c.FloodCover
, c.AnySpecifiedItems as AnySpecifiedItems_PRP
, c.[WasteRemovalStorage]
, c.[SprayPainting]
, c.[DeepFryers]
, c.[DeepFryersOilVolume]
, c.[DeepFryersCapacity]
, c.[DeepFryersExhaustSystem]
, c.[PlasticsMoulding]
, c.[DeepFryersThermostat]
, c.[PropertyDustExtractorFitted]
, c.[UnattendedEquipmentOperation]
, c.[StorageHeight]
, c.[PropertyDustExtractorCleaned]
, coalesce(c1.SumInsured,0) as SpecifiedItemsSumInsured
, c1.Category as psi_category
, svu_anal.Fire_Class
, c.ManufacturingPercentage 
, c.WashFacility
, c.FibreGlassWork
, c.StorageWarehouse
, c.RepairServicePremises
, c.RestaurantorBar
, c.Woodworking
, c.WoodworkingDustExtractorCleaning
, c.WoodworkingDustExtractors
, c.SprayPaintingControl
, c.WasteRemovalProcess
, c.TimberStorageYard



----------------------------------------------
--	BUSINESS INTERRUPTION RATING FACTORS	--
----------------------------------------------

, d.Type as BI_COVER_TYPE
, d.IndemnityPeriod as BI_IndemnityPeriod
, iif(d.IndemnityPeriodWeeks is not NULL, CONCAT(''W'',d.IndemnityPeriodWeeks), NULL) As BI_IndemnityPeriodWks
, d.SumInsured as BI_SI
, d.AICOW
, d.AccountsReceivable
, d.ClaimsPreparation
, d.LossOfRent
, d.Documents
, d.Goodwill
, d.[AdditionalDocuments]
, d.[WorkingExpensesRequired]
, d.CustomersOrSuppliersRequired
, '''' as Customer_Supplier_Type_1
, '''' as Dependency_1
, '''' Country_1
, '''' as Customer_Supplier_Type_2
, '''' as Dependency_2
, '''' Country_2

----------------------------------------------
--			THEFT RATING FACTORS			--
----------------------------------------------

, e.TheftExcess
, e.ContentsIncludingStock
, e.ContentsExcludingStock
, e.Stock
, e.Tobacco
, e.Alcohol
, e.RentedPremisesDamage
, e.TheftInOpenAir
, e.TheftNoForceItemA
, e.TheftNoForceItemB
, e.AnySpecifiedItems as AnySpecifiedItems_TFT
, ea.Category_Item0 as TFT_Specified_Item_1_Type
, ea.SumInsured_Item0 as TFT_Specified_Item_1_SI
, ea.Category_Item1 as TFT_Specified_Item_2_Type
, ea.SumInsured_Item1 as TFT_Specified_Item_2_SI
, ea.Category_Item2 as TFT_Specified_Item_3_Type
, ea.SumInsured_Item2 as TFT_Specified_Item_3_SI
, ea.Category_Item3 as TFT_Specified_Item_4_Type
, ea.SumInsured_Item3 as TFT_Specified_Item_4_SI
, ea.Category_Item4 as TFT_Specified_Item_5_Type
, ea.SumInsured_Item4 as TFT_Specified_Item_5_SI
, ea.Category_Item5 as TFT_Specified_Item_6_Type
, ea.SumInsured_Item5 as TFT_Specified_Item_6_SI

----------------------------------------------
--			MONEY RATING FACTORS			--
----------------------------------------------

, f.MoneyExcess
, f.BlanketCover
, f.MoneyInTransit
, f.MoneyBusinessHours
, f.MoneyOutsideHours
, f.MoneySafeOrStrongroom
, f.MoneyInCustody


----------------------------------------------
--				TAX AUDIT FACTORS			--
----------------------------------------------

, g.TaxAuditExcess
, g.SumInsured as TAX_SI
, g.PreviousTaxAudits


----------------------------------------------
--	  EMPLOYEE DISHONESTY RATING FACTORS	--
----------------------------------------------
, h.EmployeeDishonestyExcess
, h.SumInsured as EED_SI


----------------------------------------------
--	 MACHINERY BREAKDOWN RATING FACTORS		--
----------------------------------------------

, i.MachineryExcess
, i.NumberOfUnits
, i.LimitAnyOneLoss
, i.DeteriorationOfStock as MBD_DeteriorationOfStock
, i.AnyBlanketMachineUnits
, i.AnySpecifiedItems AS AnySpecifiedItems_MBD
, ia.MachineryType_1 as Blanket_Item_Type_1
, ia.NumberOfUnits_1 as Number_of_Units_1
, ia.MachineryType_2 as Blanket_Item_Type_2
, ia.NumberOfUnits_2 as Number_of_Units_2
, ia.MachineryType_3 as Blanket_Item_Type_3
, ia.NumberOfUnits_3 as Number_of_Units_3
, ia.MachineryType_4 as Blanket_Item_Type_4
, ia.NumberOfUnits_4 as Number_of_Units_4
, ia.MachineryType_5 as Blanket_Item_Type_5
, ia.NumberOfUnits_5 as Number_of_Units_5
, ia.MachineryType_6 as Blanket_Item_Type_6
, ia.NumberOfUnits_6 as Number_of_Units_6
, ia.MachineryType_7 as Blanket_Item_Type_7
, ia.NumberOfUnits_7 as Number_of_Units_7
, ia.MachineryType_8 as Blanket_Item_Type_8
, ia.NumberOfUnits_8 as Number_of_Units_8
, ia.MachineryType_9 as Blanket_Item_Type_9
, ia.NumberOfUnits_9 as Number_of_Units_9
, ia.MachineryType_10 as Blanket_Item_Type_10
, ia.NumberOfUnits_10 as Number_of_Units_10
, ia.MachineryType_11 as Blanket_Item_Type_11
, ia.NumberOfUnits_11 as Number_of_Units_11
, ia.MachineryType_12 as Blanket_Item_Type_12
, ia.NumberOfUnits_12 as Number_of_Units_12
, ia.MachineryType_13 as Blanket_Item_Type_13
, ia.NumberOfUnits_13 as Number_of_Units_13
, ia.MachineryType_14 as Blanket_Item_Type_14
, ia.NumberOfUnits_14 as Number_of_Units_14
, ia.MachineryType_15 as Blanket_Item_Type_15
, ia.NumberOfUnits_15 as Number_of_Units_15
, ia.MachineryType_16 as Blanket_Item_Type_16
, ia.NumberOfUnits_16 as Number_of_Units_16
, ia.MachineryType_17 as Blanket_Item_Type_17
, ia.NumberOfUnits_17 as Number_of_Units_17
, ia.MachineryType_18 as Blanket_Item_Type_18
, ia.NumberOfUnits_18 as Number_of_Units_18
, ib.Category_1 as MBD_Specified_Item_1_Type
, ib.SumInsured_1 as MBD_Specified_Item_1_SI
, ib.Category_2 as MBD_Specified_Item_2_Type
, ib.SumInsured_2 as MBD_Specified_Item_2_SI
, ib.Category_3 as MBD_Specified_Item_3_Type
, ib.SumInsured_3 as MBD_Specified_Item_3_SI
, ib.Category_4 as MBD_Specified_Item_4_Type
, ib.SumInsured_4 as MBD_Specified_Item_4_SI
, ib.Category_5 as MBD_Specified_Item_5_Type
, ib.SumInsured_5 as MBD_Specified_Item_5_SI
, ib.Category_6 as MBD_Specified_Item_6_Type
, ib.SumInsured_6 as MBD_Specified_Item_6_SI
, ib.Category_7 as MBD_Specified_Item_7_Type
, ib.SumInsured_7 as MBD_Specified_Item_7_SI
, ib.Category_8 as MBD_Specified_Item_8_Type
, ib.SumInsured_8 as MBD_Specified_Item_8_SI
, ib.Category_9 as MBD_Specified_Item_9_Type
, ib.SumInsured_9 as MBD_Specified_Item_9_SI
, ib.Category_10 as MBD_Specified_Item_10_Type
, ib.SumInsured_10 as MBD_Specified_Item_10_SI
, ib.Category_11 as MBD_Specified_Item_11_Type
, ib.SumInsured_11 as MBD_Specified_Item_11_SI
, ib.Category_12 as MBD_Specified_Item_12_Type
, ib.SumInsured_12 as MBD_Specified_Item_12_SI
, ib.Category_13 as MBD_Specified_Item_13_Type
, ib.SumInsured_13 as MBD_Specified_Item_13_SI
, ib.Category_14 as MBD_Specified_Item_14_Type
, ib.SumInsured_14 as MBD_Specified_Item_14_SI
, ib.Category_15 as MBD_Specified_Item_15_Type
, ib.SumInsured_15 as MBD_Specified_Item_15_SI
, ib.Category_16 as MBD_Specified_Item_16_Type
, ib.SumInsured_16 as MBD_Specified_Item_16_SI
, ib.Category_17 as MBD_Specified_Item_17_Type
, ib.SumInsured_17 as MBD_Specified_Item_17_SI
, ib.Category_18 as MBD_Specified_Item_18_Type
, ib.SumInsured_18 as MBD_Specified_Item_18_SI
, ib.Category_19 as MBD_Specified_Item_19_Type
, ib.SumInsured_19 as MBD_Specified_Item_19_SI
, ib.Category_20 as MBD_Specified_Item_20_Type
, ib.SumInsured_20 as MBD_Specified_Item_20_SI
, ib.Category_21 as MBD_Specified_Item_21_Type
, ib.SumInsured_21 as MBD_Specified_Item_21_SI
, ib.Category_22 as MBD_Specified_Item_22_Type
, ib.SumInsured_22 as MBD_Specified_Item_22_SI
, ib.Category_23 as MBD_Specified_Item_23_Type
, ib.SumInsured_23 as MBD_Specified_Item_23_SI
, ib.Category_24 as MBD_Specified_Item_24_Type
, ib.SumInsured_24 as MBD_Specified_Item_24_SI
, ib.Category_25 as MBD_Specified_Item_25_Type
, ib.SumInsured_25 as MBD_Specified_Item_25_SI
, ib.Category_26 as MBD_Specified_Item_26_Type
, ib.SumInsured_26 as MBD_Specified_Item_26_SI


----------------------------------------------
--		ELECTRONIC EQUIPMENT RATING FACTORS	--
----------------------------------------------

, j.ElectronicEquipmentExcess
, j.DeteriorationOfStock as EEQ_DeteriorationOfStock
, j.AnySpecifiedItems AS AnySpecifiedItems_EEQ
, ja.Category_1 as EEQ_Specified_Item_1_Type
, ja.SumInsured_1 as EEQ_Specified_Item_1_SI
, ja.Category_2 as EEQ_Specified_Item_2_Type
, ja.SumInsured_2 as EEQ_Specified_Item_2_SI
, ja.Category_3 as EEQ_Specified_Item_3_Type
, ja.SumInsured_3 as EEQ_Specified_Item_3_SI
, ja.Category_4 as EEQ_Specified_Item_4_Type
, ja.SumInsured_4 as EEQ_Specified_Item_4_SI
, ja.Category_5 as EEQ_Specified_Item_5_Type
, ja.SumInsured_5 as EEQ_Specified_Item_5_SI
, ja.Category_6 as EEQ_Specified_Item_6_Type
, ja.SumInsured_6 as EEQ_Specified_Item_6_SI


---------------------------------------------
--			GLASS RATING FACTORS		   --
---------------------------------------------	
, k.GlassExcess
, k.ExternalGlass
, k.InternalGlass
, k.Signs
, k.AnySpecifiedItems AS AnySpecifiedItems_GLS




----------------------------------------------
--		  LIABILITY RATING FACTORS			--
----------------------------------------------
, l.LiabilityExcess
, l.EngageContractors
, l.EnsureContractorsLiability
, l.LabourOnlyPayment
, l.LabourPlantPayment
, l.LabourPlantMaterialPayment
, l.EngageLabourHire
, l.EstimateLabourHireCosts
, l.HandleHazardousMaterials
, l.DischargeHazardousMaterials
, l.VehCoverFaultyWorkmanshipTurnover
, l.VehicleCoverFaultyWorkmanship
, l.DesignatedContracts
, l.ImportedGoodsRequired
, la.Turnover_1 as ImportGood_Turnover_1
, la.Country_1 as ImportGood_Country_1
, la.Turnover_2 as ImportGood_Turnover_2
, la.Country_2 as ImportGood_Country_2
, la.Turnover_3 as ImportGood_Turnover_3
, la.Country_3 as ImportGood_Country_3
, la.Turnover_4 as ImportGood_Turnover_4
, la.Country_4 as ImportGood_Country_4
, la.Turnover_5 as ImportGood_Turnover_5
, la.Country_5 as ImportGood_Country_5
, la.Turnover_6 as ImportGood_Turnover_6
, la.Country_6 as ImportGood_Country_6
, la.Turnover_7 as ImportGood_Turnover_7
, la.Country_7 as ImportGood_Country_7
, la.Turnover_8 as ImportGood_Turnover_8
, la.Country_8 as ImportGood_Country_8
, la.Turnover_9 as ImportGood_Turnover_9
, la.Country_9 as ImportGood_Country_9
, la.Turnover_10 as ImportGood_Turnover_10
, la.Country_10 as ImportGood_Country_10
, l.HireAgreement
, l.HireEquipment
, l.EquipmentMaintenance
, isnull(l.HireEquipmentTurnover,l.EquipmentTurnover) as HireEquipmentTurnover
, l.LimitOfLiabilityPublicProducts
, l.LimitOfLiabilityPublicOnly
, l.PropertyInPhysicalLegalControl
, l.NorthAmericaExports
, l.MotorTradeIncludingDelivery  
, l.MotorTradeExcludingDelivery 


---------------------------------------
--	GENERAL PROPERTY RATING FACTOR	 --
---------------------------------------

, m.GeneralPropertyExcess
, m.UnspecifiedBusinessItems
, '''' as worldwide_cover
, m.FireTheftCollision
, m.AnySpecifiedItems as AnySpecifiedItems_GPT
, mb.suminsured as [nsi_sum_insured]
, mb.Category as [nsi_category]



-----------------------------
--	TRANSIT RATING FACTOR  --
-----------------------------
, n.TransitExcess
, n.annualsendings
, n.GoodsInTransit
, o.tenant_count


--------------------
--	SECTION FLAGS --
--------------------

, case when c.policy_id is not null then 1 else 0 end as PROPERTY_SECTION_TAKEN
, case when d.policy_id is not null then 1 else 0 end as BI_SECTION_TAKEN
, case when e.policy_id is not null then 1 else 0 end as THEFT_SECTION_TAKEN
, case when f.policy_id is not null then 1 else 0 end as MONEY_SECTION_TAKEN
, case when g.policy_id is not null then 1 else 0 end as TAX_SECTION_TAKEN
, case when h.policy_id is not null then 1 else 0 end as EMPLOYEE_SECTION_TAKEN
, case when i.policy_id is not null then 1 else 0 end as MACHINERY_SECTION_TAKEN
, case when j.policy_id is not null then 1 else 0 end as ELECTRIONIC_SECTION_TAKEN
, case when k.policy_id is not null then 1 else 0 end as GLASS_SECTION_TAKEN
, case when l.policy_id is not null then 1 else 0 end as LIABILITY_SECTION_TAKEN
, case when m.policy_id is not null then 1 else 0 end as GENERAL_PROPERTY_SECTION_TAKEN
, case when n.policy_id is not null then 1 else 0 end as TRANSIT_SECTION_TAKEN


, a.[OverrideDescription]
, c.PropertyPrintableNotes
, clm.clm_cnt_total, clm.clm_cnt_nonBI, clm.inc_sum_last2Y
, iif(dodf.HasBeenRefusedInsurance is null, ''No'', ''Yes'') as HasBeenRefusedInsurance
, iif(dodf.HasBeenBankrupt is null, ''No'', ''Yes'') as HasBeenBankrupt
, iif(dodf.HasBeenInvolvedInInsolvency is null, ''No'', ''Yes'') as HasBeenInvolvedInInsolvency
, iif(dodf.HasCriminalOffences is null, ''No'', ''Yes'') as HasCriminalOffences
, iif(dodf.HasCivilOffences is null, ''No'', ''Yes'') as HasCivilOffences
, iif(dodf.HasOtherMatters is null, ''No'', ''Yes'') as HasOtherMatters
, case
	when dodf.EventDescription = ''YES'' THEN ''YES''
	when dodf.HasBeenBankrupt = ''YES''  THEN ''YES''
	when dodf.HasBeenInvolvedInInsolvency = ''YES''  THEN ''YES''
	when dodf.HasBeenRefusedInsurance = ''YES''  THEN ''YES''
	when dodf.HasCivilOffences = ''YES''  THEN ''YES''
	when dodf.HasCriminalOffences = ''YES''  THEN ''YES''
	when dodf.HasOtherMatters = ''YES''  THEN ''YES''
	when dodf.InsolventDirector = ''YES''  THEN ''YES''
	when dodf.ListOfBankruptcies = ''YES''  THEN ''YES''
	when dodf.ListOfCivilOffences = ''YES''  THEN ''YES''
	when dodf.ListOfCriminalOffences = ''YES''  THEN ''YES''
	when dodf.ListOfInsolvencies = ''YES'' THEN ''YES''
	when dodf.ListOfPolicyRefusals = ''YES'' THEN ''YES''
	when dodf.SpecificCriminalOffences = ''YES'' THEN ''YES''
	when dodf.VoluntaryBankruptcy = ''YES'' THEN ''YES''
	else ''NO'' 
	end as Disclosure_yes

, svu_anal.modified_date

, iif(clm.claimLoading_flag = ''Yes'', ld1.int_property_a, 1) as claimLoading
, iif(clm.CLLoading_flag = ''Yes'', ld2.int_property_a, 1) as CLLoading 
, iif(clm.CL01Loding_prpOnly_flag = ''Yes'', 1.15, 1) as CL01Loding_prpOnly --1.15 in Core
, iif(dod.policy_id is not null, ld3.int_property_a, 1) as DDLoading
, iif(c.PropertyPrintableNotes = ''yes'', ld4.int_property_a, 1) as PNLoading
, iif(c.FloodCover = ''yes'', ld6.int_property_a, 1) as floodloading
, iif(
--SS_24
	   a.[OverrideDescription] like ''%Ammunition%''
	or a.[OverrideDescription] like ''%Salvage%''
	or a.[OverrideDescription] like ''%Reclaim%''
	or a.[OverrideDescription] like ''%Recycl%''
	or a.[OverrideDescription] like ''%Explosive%''
	or a.[OverrideDescription] like ''%Asbestos%''
	or a.[OverrideDescription] like ''%shisha%''
	or a.[OverrideDescription] like ''%Hookah%''
	or a.[OverrideDescription] like ''%Tattoo%''
	or a.[OverrideDescription] like ''%Amusement%''
	or a.[OverrideDescription] like ''%Skip%''
	or a.[OverrideDescription] like ''%Rubbish%''
	or a.[OverrideDescription] like ''%Fertilis%''
	or a.[OverrideDescription] like ''%Firewood%''
	or a.[OverrideDescription] like ''%Quarr%''
	or a.[OverrideDescription] like ''%Abattoir%''
	or a.[OverrideDescription] like ''%Sawmill%''
	or a.[OverrideDescription] like ''%Dynamite%''
	or a.[OverrideDescription] like ''%Fireworks%''
	or a.[OverrideDescription] like ''%Logistic%''
	or a.[OverrideDescription] like ''%Toxic%''
	or a.[OverrideDescription] like ''%Peroxide%''
	or a.[OverrideDescription] like ''%Oxidising%''
	or a.[OverrideDescription] like ''%Radioactive%''
	or a.[OverrideDescription] like ''%Corrosive%''
	or a.[OverrideDescription] like ''%Stockfeed%''
	or a.[OverrideDescription] like ''%Composite%''
	or a.[OverrideDescription] like ''%Clad%''
	or a.[OverrideDescription] like ''%Hibernat%''
	or a.[OverrideDescription] like ''%Mask%''
	or a.[OverrideDescription] like ''%Sanitiz%''
	or a.[OverrideDescription] like ''%N95%''
	or a.[OverrideDescription] like ''%Anti-Bacterial%''
	or a.[OverrideDescription] like ''%Pandemic%''
	or a.[OverrideDescription] like ''%jetty%''
	or a.[OverrideDescription] like ''%jetties%''
	or a.[OverrideDescription] like ''%wharf%''
	or a.[OverrideDescription] like ''%wharve%''
	or a.[OverrideDescription] like ''%shipyard%''
	or a.[OverrideDescription] like ''%slipway%''
	or a.[OverrideDescription] like ''%saleyard%''
	or a.[OverrideDescription] like ''%sale yard%''
	or a.[OverrideDescription] like ''%stockyard%''
	or a.[OverrideDescription] like ''%stock yard%''
	or a.[OverrideDescription] like ''%polyst%''
	or a.[OverrideDescription] like ''%mooring%''
	or a.[OverrideDescription] like ''%scheme%''
	or a.[OverrideDescription] like ''%backpacker%''
	or a.[OverrideDescription] like ''%hostel%''
	or a.[OverrideDescription] like ''%boarding house%''
	or a.[OverrideDescription] like ''%pontoon%''
	or a.[OverrideDescription] like ''%solarium%''
	or a.[OverrideDescription] like ''%crisis acc%''
	or a.[OverrideDescription] like ''%refuge%''
	or a.[OverrideDescription] like ''%waste coll%''
	or a.[OverrideDescription] like ''%wreck%''
	or a.[OverrideDescription] like ''%charcoal%''
	or a.[OverrideDescription] like ''%strata plan%''
	or a.[OverrideDescription] like ''%common area%''
	or a.[OverrideDescription] like ''%bodycorp%''
	or a.[OverrideDescription] like ''%body corp%''
	or a.[OverrideDescription] like ''%owners corp%''
	or a.[OverrideDescription] like ''%strata corp%''
	or a.[OverrideDescription] like ''%strata owner%''
	or a.[OverrideDescription] like ''%growing%''
	or a.[OverrideDescription] like ''%pryoxylin%''
	or a.[OverrideDescription] like ''%celluloid%''
	or a.[OverrideDescription] like ''%bailing%''
	or a.[OverrideDescription] like ''%silage%''
	or a.[OverrideDescription] like ''%hay%''
	or a.[OverrideDescription] like ''%chaff%''
	or a.[OverrideDescription] like ''%drench%''
	or a.[OverrideDescription] like ''%vineyard%''
	or a.[OverrideDescription] like ''%glycerine%''
	or a.[OverrideDescription] like ''%landfill%''
	or a.[OverrideDescription] like ''%display ho%''
	or a.[OverrideDescription] like ''%docks%''
	or a.[OverrideDescription] like ''%fung%''
	or a.[OverrideDescription] like ''%fumi%''
	or a.[OverrideDescription] like ''%herbi%''
	or a.[OverrideDescription] like ''%retread%''
	or a.[OverrideDescription] like ''%remould%''
	or a.[OverrideDescription] like ''%recap%''
	or a.[OverrideDescription] like ''%regenerat%''
	or a.[OverrideDescription] like ''%disinfectant%''
	or a.[OverrideDescription] like ''%detergent%''
	or a.[OverrideDescription] like ''%bleach%''
	or a.[OverrideDescription] like ''%aerosol%''
	or a.[OverrideDescription] like ''%decant%''
	or a.[OverrideDescription] like ''%farm supp%''
	or a.[OverrideDescription] like ''%farm stay%''
	or a.[OverrideDescription] like ''%farmstay%''
	or a.[OverrideDescription] like ''%b&b%''
	or a.[OverrideDescription] like ''%b & b%''
	or a.[OverrideDescription] like ''%bed & break%''
	or a.[OverrideDescription] like ''%bed and break%''
	or a.[OverrideDescription] like ''%spreading%''
	or a.[OverrideDescription] like ''%retreat%''
	or a.[OverrideDescription] like ''%pylon%''
	or a.[OverrideDescription] like ''%rockwool%''
	or a.[OverrideDescription] like ''%glasswool%''
	or a.[OverrideDescription] like ''%fibreglass%''
	or a.[OverrideDescription] like ''%barge%''
	or a.[OverrideDescription] like ''%jackaroo%''
	or a.[OverrideDescription] like ''%jillaroo%''
	or a.[OverrideDescription] like ''%farmhand%''
	or a.[OverrideDescription] like ''%farm hand%''
	or a.[OverrideDescription] like ''%stables%''
	or a.[OverrideDescription] like ''%bond stor%''
	or a.[OverrideDescription] like ''%cold stor%''
	or a.[OverrideDescription] like ''%coldstor%''
	or a.[OverrideDescription] like ''%grain stor%''
	or a.[OverrideDescription] like ''%infectious%''
	--SS_25
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%Pest%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%Termite%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%Mining%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%Firearm%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%Concert%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%Hazardous%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%Demolition%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%Exploration%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%Blasting%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%Logging%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%Dredging%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%Forest%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%Insecticide%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%Poison%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%Firebreak%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%Dewatering%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%Scaffold%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%Hydraulic%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%Cured%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%Fermented%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%Subaqueous%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%Underwater%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%Offshore%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%Petrochemical%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%Refiner%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%Obedience%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%Training%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%telecasting%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%broadcasting%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%muster%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%agisting%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%agistment%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%seawall%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%sea wall%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%power station%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%powerstation%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%carnival%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%circus%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%tunnel%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%underground min%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%underground bor%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%bore drill%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%directional drill%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%structural metal%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%structural steel%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%dams%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%weir%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%reservoir%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%chairlift%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%cablecar%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%tramway%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%railway%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%ndis prov%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%power line%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%powerline%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%transmission line%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%distribution line%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%pole danc%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%pole driv%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%public foot%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%public road%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%mine shaft%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%mineshaft%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%tarmac%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%runway%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%deton%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%dry hir%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%sub station%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%substation%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%avionic%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%escalat%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%elevat%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%aircraft%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%drill rig%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%drilling rig%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%oil rig%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%rigg%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%civil w%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%civil con%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%freight f%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%customs ag%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%customs cl%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%customs br%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%model plane%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%model aero%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%airplane%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%aero club%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%aeroplane%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%brewery%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%airside%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%utilities%'')
	or (l.policy_id is not null and a.Category not in (''Property Owner'', ''PropertyOwner'') and a.[OverrideDescription] like ''%harvest%'')

	, ld5.int_property_a, 1) as SSLoading
into CalibreSSiSdev.emula.testing_input_temp1_'+@suffix+'
from CalibreSSiSdev.svu.SECTION_SIT a 
	left join CalibreSSiSdev.svu.tenant_occ2 a0
	on  a.address_id = a0.address_id
	left join CalibreSSiSdev.svu.SECTION_SNL aa
	on a.address_id = aa.ADDRESS_ID
	left join CalibreSSiSdev.svu.fireprotection ac
	on a.address_id = ac.address_id 
	left join CalibreSSiSdev.svu.security ad
	on a.address_id = ad.ADDRESS_ID
	left join CalibreSSiSdev.svu.ADDRESS b
	on a.address_id = b.ADDRESS_ID
	left join 
	(select policy_id, max(state) as state 
	from CalibreSSiSdev.svu.ADDRESS
	group by policy_id) b2
	on a.policy_id = b2.POLICY_ID
	left join CalibreSSiSdev.svu.SECTION_PRP c
	on a.address_id = c.address_id
	left join CalibreSSiSdev.svu.section_psi c1
	on a.address_id = c1.address_id
	left join CalibreSSiSdev.svu.SECTION_BIC d
	on a.address_id = d.address_id 
	left join CalibreSSiSdev.svu.SECTION_TFT e
	on a.address_id = e.address_id
	left join CalibreSSiSdev.svu.section_tsi ea
	on a.address_id = ea.address_id
	left join CalibreSSiSdev.svu.SECTION_MON f
	on a.address_id = f.address_id
	left join CalibreSSiSdev.svu.SECTION_TAX g
	on a.address_id = g.address_id
	left join CalibreSSiSdev.svu.SECTION_EED h
	on a.address_id = h.address_id
	left join CalibreSSiSdev.svu.SECTION_MBD i
	on a.address_id = i.address_id
	left join CalibreSSiSdev.svu.SECTION_MSI ib
	on  a.address_id = ib.address_id
	left join CalibreSSiSdev.svu.section_mbi ia
	on a.address_id = ia.address_id
	left join CalibreSSiSdev.svu.SECTION_EEQ j
	on a.address_id = j.address_id
	left join CalibreSSiSdev.svu.SECTION_QSI ja
	on a.address_id = ja.address_id
	left join CalibreSSiSdev.svu.SECTION_GLS k
	on  a.address_id = k.address_id
	left join CalibreSSiSdev.svu.SECTION_LIC l
	on a.policy_id = l.policy_id and a.address_id = l.address_id
	left join CalibreSSiSdev.svu.SECTION_LIM la
	on a.policy_id = la.policy_id and a.address_id = la.address_id
	left join CalibreSSiSdev.svu.SECTION_GPT m
	on a.policy_id = m.policy_id and a.address_id = m.address_id
	left join [CalibreSSiSdev].[svu].[SECTION_NSI] mb
	on  a.address_id = mb.address_id
	left join CalibreSSiSdev.svu.SECTION_TRN n
	on a.policy_id = n.policy_id and a.address_id = n.address_id
	left join CalibreSSiSdev.svu.tenant_count o
	on a.policy_id = o.policy_id and a.address_id = o.address_id
	left join #claim_loading clm 
	on a.policy_id = clm.policy_id
	left join (select distinct POLICY_ID from CalibreSSiSdev.svu.s_pol_all WHERE Property_code_value = ''Yes'' and PROPERTY_REF like ''dod.%'' and PROPERTY_REF <> ''dod.Acknowledgement'') dod on a.policy_id = dod.policy_id
	left join CalibreSSiSdev.svu.s_pol_all_final dodf on a.policy_id = dodf.policy_id
	left join #ccomm_data_loading ld1 on a.policy_id is not null and ld1.groupid = ''claimLoading''
	left join #ccomm_data_loading ld2 on a.policy_id is not null and ld2.groupid = ''CLLoading''
	left join #ccomm_data_loading ld3 on a.policy_id is not null and ld3.groupid = ''DDLoading''
	left join #ccomm_data_loading ld4 on a.policy_id is not null and ld4.groupid = ''PNLoading''
	left join #ccomm_data_loading ld5 on a.policy_id is not null and ld5.groupid = ''SSLoading''
	left join #ccomm_data_loading ld6 on a.policy_id is not null and ld6.groupid = ''flood''    and ld6.code = ''Yes''
	
	inner join InforceBook svu_anal
	on a.address_id = svu_anal.address_id
Where a.address_id is not null and svu_anal.LatestTransTerm = 1 and svu_anal.status_code like ''ONRISK%''
;'
;


--------------------------------------
--			Final Input Table		--
--------------------------------------
SET @Input_Emulation_Step3='

drop table if exists  CalibreSSiSdev.emula.testing_input_temp2_'+@suffix+'
select a.*
	, (select count(*) from (values(a.Tenant1_Occ), (a.Tenant2_Occ), (Tenant3_Occ), (Tenant4_Occ), (Tenant5_Occ), (Tenant6_Occ), (Tenant7_Occ)) as OSQ(OSQ107) where OSQ.OSQ107 is not null and b1.text_property_a like iif(OSQ.OSQ107 is not NULL, CONCAT(''%'',OSQ.OSQ107, ''%''), NULL)) As OSQ107_Count
	, (select count(*) from (values(a.Tenant1_Occ), (a.Tenant2_Occ), (Tenant3_Occ), (Tenant4_Occ), (Tenant5_Occ), (Tenant6_Occ), (Tenant7_Occ)) as OSQ(OSQ100) where OSQ.OSQ100 is not null and b2.text_property_a like iif(OSQ.OSQ100 is not NULL, CONCAT(''%'',OSQ.OSQ100, ''%''), NULL)) As OSQ100_Count
	, (select count(*) from (values(a.Tenant1_Occ), (a.Tenant2_Occ), (Tenant3_Occ), (Tenant4_Occ), (Tenant5_Occ), (Tenant6_Occ), (Tenant7_Occ)) as OSQ(OSQ104) where OSQ.OSQ104 is not null and b3.text_property_a like iif(OSQ.OSQ104 is not NULL, CONCAT(''%'',OSQ.OSQ104, ''%''), NULL)) As OSQ104_Count
	, (select count(*) from (values(a.Tenant1_Occ), (a.Tenant2_Occ), (Tenant3_Occ), (Tenant4_Occ), (Tenant5_Occ), (Tenant6_Occ), (Tenant7_Occ)) as OSQ(OSQ99) where OSQ.OSQ99 is not null and b4.text_property_a like iif(OSQ.OSQ99 is not NULL, CONCAT(''%'',OSQ.OSQ99, ''%''), NULL)) As OSQ99_Count
	, (select count(*) from (values(a.Tenant1_Occ), (a.Tenant2_Occ), (Tenant3_Occ), (Tenant4_Occ), (Tenant5_Occ), (Tenant6_Occ), (Tenant7_Occ)) as OSQ(OSQ111) where OSQ.OSQ111 is not null and b5.text_property_a like iif(OSQ.OSQ111 is not NULL, CONCAT(''%'',OSQ.OSQ111, ''%''), NULL)) As OSQ111_Count
	, (select count(*) from (values(a.Tenant1_Occ), (a.Tenant2_Occ), (Tenant3_Occ), (Tenant4_Occ), (Tenant5_Occ), (Tenant6_Occ), (Tenant7_Occ)) as OSQ(OSQ112A) where OSQ.OSQ112A is not null and b6.text_property_a like iif(OSQ.OSQ112A is not NULL, CONCAT(''%'',OSQ.OSQ112A, ''%''), NULL)) As OSQ112A_Count
	, (select count(*) from (values(a.Tenant1_Occ), (a.Tenant2_Occ), (Tenant3_Occ), (Tenant4_Occ), (Tenant5_Occ), (Tenant6_Occ), (Tenant7_Occ)) as OSQ(OSQ112B) where OSQ.OSQ112B is not null and b7.text_property_a like iif(OSQ.OSQ112B is not NULL, CONCAT(''%'',OSQ.OSQ112B, ''%''), NULL)) As OSQ112B_Count

into CalibreSSiSdev.emula.testing_input_temp2_'+@suffix+'
from CalibreSSiSdev.emula.testing_input_temp1_'+@suffix+' a
	left join CalibreSSiSdev.dbo.ccomm_data_final b1 on b1.groupid = ''OSQ107'' and b1.code = ''ANSZIC'' and b1.Current_Flag=''YES''
	left join CalibreSSiSdev.dbo.ccomm_data_final b2 on b2.groupid = ''OSQ100'' and b2.code = ''ANSZIC'' and b2.Current_Flag=''YES''
	left join CalibreSSiSdev.dbo.ccomm_data_final b3 on b3.groupid = ''OSQ104'' and b3.code = ''ANSZIC'' and b3.Current_Flag=''YES''
	left join CalibreSSiSdev.dbo.ccomm_data_final b4 on b4.groupid = ''OSQ99'' and b4.code = ''ANSZIC'' and b4.Current_Flag=''YES''
	left join CalibreSSiSdev.dbo.ccomm_data_final b5 on b5.groupid = ''OSQ111'' and b5.code = ''ANSZIC'' and b5.Current_Flag=''YES''
	left join CalibreSSiSdev.dbo.ccomm_data_final b6 on b6.groupid = ''OSQ112'' and b6.code = ''LIST3A'' and b6.Current_Flag=''YES''
	left join CalibreSSiSdev.dbo.ccomm_data_final b7 on b7.groupid = ''OSQ112'' and b7.code = ''LIST3B'' and b7.Current_Flag=''YES''

;



drop table if exists  CalibreSSiSdev.emula.testing_input_'+@suffix+'
select a.*, b.Policy_situation_count, c.Liab_situation_count, c.liab_sum_AnnualTurnover
, iif(a.Category=''Non_PO'', ''No'', ''Yes'') as Category_label
into CalibreSSiSdev.emula.testing_input_'+@suffix+'
from CalibreSSiSdev.emula.testing_input_temp2_'+@suffix+' a
left join (select  policy_number, policy_id, count(*) as Policy_situation_count 
			from  CalibreSSiSdev.emula.testing_input_temp1_'+@suffix+'
			group by  policy_number, policy_id
			) b   -- This situation count is the total situation count for the policy, not necessary for each covered section
			on a.policy_number = b.policy_number and a.policy_id = b.policy_id
left join (select  policy_number, policy_id, count(*) as Liab_situation_count, sum(coalesce(AnnualTurnover,0)) as liab_sum_AnnualTurnover
			from  CalibreSSiSdev.emula.testing_input_temp2_'+@suffix+'
			where LIABILITY_SECTION_TAKEN = 1 
			group by  policy_number, policy_id
			) c 
on a.policy_number = c.policy_number and a.policy_id = c.policy_id
;';

EXEC(@Input_Emulation_Step1 + @Input_Emulation_Step2 + @Input_Emulation_Step3);

END
GO


