USE [CalibreSSiSdev]
GO

/****** Object:  StoredProcedure [emula].[OM_BusPack_Emulation_Prep_B]    Script Date: 4/06/2024 5:47:06 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE procedure [emula].[OM_BusPack_Emulation_Prep_B] 
( @suffix varchar(99)
, @version varchar(99) 
) AS
BEGIN

DECLARE
-- Load all rating factor tables into CalibreSSiSdev tables for further manipulation
  @VersionControl_Emulation_Step1 NVARCHAR(MAX),
  @VersionControl_Emulation_Step2 NVARCHAR(MAX)

;

Set @VersionControl_Emulation_Step1 ='


----- Update the Relativity Tables

---- Update Property SI Curve table

exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS]
@in_tablename = ''dbo.ccomm_businessproperty_sicurve_'+@suffix+''',
@out_tablename = ''dbo.ccomm_businessproperty_sicurve_'+@suffix+'_'+@version+''',
@clause = '''',
@part_key = ''state
      ,type
      ,suminsuredfrom
      ,suminsuredto''

Alter Table calibressisdev.dbo.ccomm_businessproperty_sicurve_'+@suffix+'_'+@version+'
Add premiumlow_PreCRP int Not NULL Default(0) 

Alter Table calibressisdev.dbo.ccomm_businessproperty_sicurve_'+@suffix+'_'+@version+'
Add premiumhi_PreCRP int Not NULL Default(0) 

Alter Table calibressisdev.dbo.ccomm_businessproperty_sicurve_'+@suffix+'_'+@version+'
Add newrate_PreCRP int Not NULL Default(0) 

Alter Table calibressisdev.dbo.ccomm_businessproperty_sicurve_'+@suffix+'_'+@version+'
Add premiumlow_PostCRP int Not NULL Default(0) 

Alter Table calibressisdev.dbo.ccomm_businessproperty_sicurve_'+@suffix+'_'+@version+'
Add premiumhi_PostCRP int Not NULL Default(0) 

Alter Table calibressisdev.dbo.ccomm_businessproperty_sicurve_'+@suffix+'_'+@version+'
Add newrate_PostCRP int Not NULL Default(0) 

---- Update Property table

-- Replace Null Values with Blanks
drop table if exists  calibressisdev.dbo.ccomm_businessproperty_temp;
select
	groupid
	, iif(code is null, '''',code) as code
	, iif(rangefield is null, '''', rangefield) as rangefield
	, iif(lowerfrom is null, '''', lowerfrom) as lowerfrom
	, iif(upperto is null, '''', upperto) as upperto
	, iif(relativitytype is null, '''', relativitytype) as relativitytype
	, iif(value is null, '''', value) as value
	, version
into calibressisdev.dbo.ccomm_businessproperty_temp
from calibressisdev.dbo.ccomm_businessproperty_'+@suffix+'

--Apply Current Flags
exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS]
@in_tablename = ''calibressisdev.dbo.ccomm_businessproperty_temp'',
@out_tablename = ''calibressisdev.dbo.ccomm_businessproperty_'+@suffix+'_'+@version+''',
@clause = '''',
@part_key = ''groupid
      ,code
      ,rangefield
      ,lowerfrom
	  ,upperto
	  ,relativitytype''

drop table if exists  calibressisdev.dbo.ccomm_businessproperty_temp



---- Update Occupation table


exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS]
@in_tablename = ''calibressisdev.dbo.ccomm_occupation_'+@suffix+''',
@out_tablename = ''calibressisdev.dbo.ccomm_occupation_'+@suffix+'_'+@version+''',
@clause = '''',
@part_key = ''calliden_code''



---- Update Excess table
exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS]
@in_tablename = ''calibressisdev.dbo.ccomm_excess_'+@suffix+''',
@out_tablename = ''calibressisdev.dbo.ccomm_excess_'+@suffix+'_'+@version+''',
@clause = '''',
@part_key = ''relativitytype
      ,state
	  ,excessvalue''
    


---- Update Location table
exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS]
@in_tablename = ''calibressisdev.dbo.ccomm_location_'+@suffix+''',
@out_tablename = ''calibressisdev.dbo.ccomm_location_'+@suffix+'_'+@version+''',
@clause = '''',
@part_key = ''locationindex''

Alter Table calibressisdev.dbo.ccomm_location_'+@suffix+'_'+@version+'
Add fireperilsrel_preCRP int Not NULL Default(1) 

Alter Table calibressisdev.dbo.ccomm_location_'+@suffix+'_'+@version+'
Add fireperilsrel_postCRP int Not NULL Default(1) 


---- Update Liability table

alter table  calibressisdev.dbo.ccomm_liability_'+@suffix+'
alter column rangeto  float

alter table  calibressisdev.dbo.ccomm_liability_'+@suffix+'
alter column rangefrom  float

update calibressisdev.dbo.ccomm_liability_'+@suffix+'
set rangeto = 0
where groupid = ''Tenants'' and rangeto = ''''

update calibressisdev.dbo.ccomm_liability_'+@suffix+'
set rangeto = 1
where rangefrom = 0.5 and rangeto = 99999

update calibressisdev.dbo.ccomm_liability_'+@suffix+'
set rangeto = 25000000, rangefrom=0
  where version <> 530 and groupid in (''FullTimeStaff'',''PartTimeStaff'') and propertyowner = ''NO''

-- Replace Nulls with Blanks
drop table if exists  calibressisdev.dbo.ccomm_liability_temp;
select 
	groupid
	, iif(propertyowner is null,'''',propertyowner) as propertyowner
	, iif(code is null, '''', code) as code
	, iif(rangefield is null, '''', rangefield) as rangefield
	, iif(rangefrom is null, '''', rangefrom) as rangefrom
	, iif(rangeto is null, '''', rangeto) as rangeto
	, relativityvalue
	, version
into calibressisdev.dbo.ccomm_liability_temp
from calibressisdev.dbo.ccomm_liability_'+@suffix+'

--Apply Current Flag
exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS]
@in_tablename = ''calibressisdev.dbo.ccomm_liability_temp'',
@out_tablename = ''calibressisdev.dbo.ccomm_liability_'+@suffix+'_'+@version+''',
@clause = '''',
@part_key = ''groupid
      ,propertyowner
	  ,code
	  ,rangefield
	  ,rangefrom
	  ,rangeto''


--create an extra column to have range for staff number
drop table if exists  calibressisdev.dbo.ccomm_liability_staff_'+@suffix+';

select isnull(lag(code, 1) over (partition by groupid, propertyowner order by cast(code as numeric) desc) 
		-1, 9999)  as code_to
, * 
into calibressisdev.dbo.ccomm_liability_staff_'+@suffix+'
from calibressisdev.dbo.ccomm_liability_'+@suffix+'_'+@version+'
where groupid in (''PartTimeStaff'', ''FullTimeStaff'', ''CombinedStaff'') and CURRENT_FLAG = ''Yes'';

drop table if exists  calibressisdev.dbo.ccomm_liability_temp;



---- Update BI table
exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS]
@in_tablename = ''calibressisdev.dbo.ccomm_bi_'+@suffix+''',
@out_tablename = ''calibressisdev.dbo.ccomm_bi_'+@suffix+'_'+@version+''',
@clause = '''',
@part_key = ''code
      ,relativitytype''



---- Update Minimum table
exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS]
@in_tablename = ''calibressisdev.dbo.ccomm_minimum_'+@suffix+''',
@out_tablename = ''calibressisdev.dbo.ccomm_minimum_'+@suffix+'_'+@version+''',
 @clause = '''',
 @part_key =''section
 ,type
 ,valuetype''
 

 ---- Update ee table

-- Replace Null with Blanks
select groupid,
iif(state is null, '''', state) as state,
iif(code is null, '''', code) as code,
value,version 
into calibressisdev.dbo.ccomm_ee_temp
 from calibressisdev.dbo.ccomm_ee_'+@suffix+'

-- Apply current flag
exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS]
@in_tablename = ''calibressisdev.dbo.ccomm_ee_temp'',
@out_tablename = ''calibressisdev.dbo.ccomm_ee_'+@suffix+'_'+@version+''',
 @clause = '''',
 @part_key =''groupid
 ,state
 ,code''

drop table if exists  calibressisdev.dbo.ccomm_ee_temp


---- Update glass table
-- Replace Null with Blanks
select groupid,
iif(propertyowner is null, '''', propertyowner) as propertyowner,
iif(code is null, '''', code) as code,
value,version 
into calibressisdev.dbo.ccomm_glass_temp
 from calibressisdev.dbo.ccomm_glass_'+@suffix+'

-- Apply Current Flag
exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS]
@in_tablename = ''calibressisdev.dbo.ccomm_glass_temp'',
@out_tablename = ''calibressisdev.dbo.ccomm_glass_'+@suffix+'_'+@version+''',
 @clause = '''',
 @part_key =''groupid
 ,propertyowner
 ,code''

drop table if exists  calibressisdev.dbo.ccomm_glass_temp;

 ---- Update GNP table

-- Replace Null with Blanks
select groupid,
iif(code is null, '''', code) as code,
value,version 
into calibressisdev.dbo.ccomm_gp_temp
 from calibressisdev.dbo.ccomm_gp_'+@suffix+'

-- Apply Current Flag
 exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS]
@in_tablename = ''calibressisdev.dbo.ccomm_gp_temp'',
@out_tablename = ''calibressisdev.dbo.ccomm_gp_'+@suffix+'_'+@version+''',
 @clause = '''',
 @part_key =''groupid
 ,code''

drop table if exists  calibressisdev.dbo.ccomm_gp_temp

  ---- Update Machinery table
-- Replace Null with Blanks
select groupid,
iif(propertyowner is null, '''', propertyowner) as propertyowner,
iif(code is null, '''', code) as code,
iif(rangefrom is null, '''', rangefrom) as rangefrom,
iif(rangeto is null, '''', rangeto) as rangeto,
value,version 
into calibressisdev.dbo.ccomm_machinery_temp
 from calibressisdev.dbo.ccomm_machinery_'+@suffix+'




';


Set @VersionControl_Emulation_Step2 ='

-- Apply Current Flag
 exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS]
@in_tablename = ''calibressisdev.dbo.ccomm_machinery_temp'',
@out_tablename = ''calibressisdev.dbo.ccomm_machinery_'+@suffix+'_'+@version+''',
 @clause = '''',
 @part_key =''groupid
 ,propertyowner
 ,code
 ,rangefrom
 ,rangeto''

drop table if exists  calibressisdev.dbo.ccomm_machinery_temp;


 ---- Update Money Table
-- Replace Null with Blanks
drop table if exists  calibressisdev.dbo.ccomm_money_temp;
select groupid,
iif(propertyowner is null, '''', propertyowner) as propertyowner,
iif(code is null, '''', code) as code,
iif(rangefrom is null, '''', rangefrom) as rangefrom,
iif(rangeto is null, '''', rangeto) as rangeto,
relativityvalue,version 
into calibressisdev.dbo.ccomm_money_temp
 from calibressisdev.dbo.ccomm_money_'+@suffix+'

-- Apply Current Flag
 exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS]
@in_tablename = ''calibressisdev.dbo.ccomm_money_temp'',
@out_tablename = ''calibressisdev.dbo.ccomm_money_'+@suffix+'_'+@version+''',
 @clause = '''',
 @part_key =''groupid
 ,propertyowner
 ,code
 ,rangefrom
 ,rangeto''
 
drop table if exists  calibressisdev.dbo.ccomm_money_temp;

 ---- Update Theft Table
-- Replace Null with Blanks
select 
	groupid
	, iif(propertyowner is null, '''', propertyowner) as propertyowner
	, iif(code is null, '''', code) as code
	, iif(rangefrom is null, '''', rangefrom) as rangefrom
	, iif(rangeto is null, '''', rangeto) as rangeto
	, relativityvalue
	, version 
into calibressisdev.dbo.ccomm_theft_temp
 from calibressisdev.dbo.ccomm_theft_'+@suffix+'

 -- Applu Current Flag
 exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS]
@in_tablename = ''calibressisdev.dbo.ccomm_theft_temp'',
@out_tablename = ''calibressisdev.dbo.ccomm_theft_'+@suffix+'_'+@version+''',
 @clause = '''',
 @part_key =''groupid
 ,propertyowner
 ,code
 ,rangefrom
 ,rangeto''


drop table if exists  calibressisdev.dbo.ccomm_theft_temp;

 ---- Update Transit Table
-- Replace Null with Blanks
drop table if exists calibressisdev.dbo.ccomm_transit_temp
select 
	groupid
	, iif(code is null, '''', code) as code
	,	cast((case when rangefrom is null then null	
			when rangefrom = '''' then 0 
			else rangefrom end) as numeric) as rangefrom
	, cast(iif(rangeto is null, null, rangeto) as numeric) as rangeto
	, value
	, version 
into calibressisdev.dbo.ccomm_transit_temp
from calibressisdev.dbo.ccomm_transit_'+@suffix+'



-- Apply Current Flag
 exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS]
@in_tablename = ''calibressisdev.dbo.ccomm_transit_temp'',
@out_tablename = ''calibressisdev.dbo.ccomm_transit_'+@suffix+'_'+@version+''',
 @clause = '''',
 @part_key =''groupid
 ,code
 ,rangefrom
 ,rangeto''

drop table if exists  calibressisdev.dbo.ccomm_transit_temp;

 ---- Update data Table

update calibressisdev.dbo.ccomm_data_'+@suffix+'
set upperto = 13
where groupid = ''MultiSectionDiscount'' and upperto = 12

-- Replace Null with Blanks
select 
	groupid
	, iif(code is null, '''', code) as code
	, iif(text_property_a is null, '''', text_property_a) as text_property_a
	, iif(text_property_b is null, '''', text_property_b) as text_property_b
	, iif(text_property_c is null, '''', text_property_c) as text_property_c
	, iif(int_property_a is null, '''', int_property_a) as int_property_a
	, iif(int_property_b is null, '''', int_property_b) as int_property_b
	, iif(int_property_c is null, '''', int_property_c) as int_property_c
	, iif(lowerfrom is null, '''', lowerfrom) as lowerfrom
	, iif(upperto is null, '''', upperto) as upperto
	, version 
into calibressisdev.dbo.ccomm_data_temp
 from calibressisdev.dbo.ccomm_data_'+@suffix+'

 -- Apply Current Flag
 exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS]
@in_tablename = ''calibressisdev.dbo.ccomm_data_temp'',
@out_tablename = ''calibressisdev.dbo.ccomm_data_'+@suffix+'_'+@version+''',
 @clause = '''',
 @part_key =''groupid
 ,code
 ,text_property_a
 ,text_property_b
 ,text_property_c
 ,lowerfrom
 ,upperto''
 


drop table if exists  calibressisdev.dbo.ccomm_data_temp;


 ---- Update Freecover Table
exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS]
@in_tablename = ''calibressisdev.dbo.ccomm_freecovers_'+@suffix+''',
@out_tablename = ''calibressisdev.dbo.ccomm_freecovers_'+@suffix+'_'+@version+''',
 @clause = '''',
 @part_key =''section
 ,covertype,product''
 

 ---- Update Scheme Table
 exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS]
@in_tablename = ''calibressisdev.dbo.ccomm_scheme_'+@suffix+''',
@out_tablename = ''calibressisdev.dbo.ccomm_scheme_'+@suffix+'_'+@version+''',
 @clause = '''',
 @part_key =''schemeid
 ,relativitytype''
 

 
--------------------------
drop table if exists CalibreSSiSdev.emula.version_max_'+@suffix+';

select ''FIRE'' as tbl, max(version) as version_max, max(effectivedate) as effe_max, max(releasedate) as release_max 
into CalibreSSiSdev.emula.version_max_'+@suffix+'
from calibressisdev.dbo.ccomm_businessproperty_sicurve_'+@suffix+'_'+@version+'
union all select ''FIRE'' as tbl, max(version) as version_max, max(effectivedate) as effe_max, max(releasedate) as release_max from calibressisdev.dbo.ccomm_businessproperty_'+@suffix+'_'+@version+'
union all select ''com_occu'' as tbl, max(version) as version_max, max(effectivedate) as effe_max, max(releasedate) as release_max from calibressisdev.dbo.ccomm_occupation_'+@suffix+'_'+@version+'
union all select ''com_excess'' as tbl, max(version) as version_max, max(effectivedate) as effe_max, max(releasedate) as release_max from calibressisdev.dbo.ccomm_excess_'+@suffix+'_'+@version+'
union all select ''com_Loca'' as tbl, max(version) as version_max, max(effectivedate) as effe_max, max(releasedate) as release_max from calibressisdev.dbo.ccomm_location_'+@suffix+'_'+@version+'
union all select ''LPUB'' as tbl, max(version) as version_max, max(effectivedate) as effe_max, max(releasedate) as release_max from calibressisdev.dbo.ccomm_liability_'+@suffix+'_'+@version+'
union all select ''BUSI'' as tbl, max(version) as version_max, max(effectivedate) as effe_max, max(releasedate) as release_max from calibressisdev.dbo.ccomm_bi_'+@suffix+'_'+@version+'
union all select ''com_min'' as tbl, max(version) as version_max, max(effectivedate) as effe_max, max(releasedate) as release_max from calibressisdev.dbo.ccomm_minimum_'+@suffix+'_'+@version+'
union all select ''ELEC'' as tbl, max(version) as version_max, max(effectivedate) as effe_max, max(releasedate) as release_max from calibressisdev.dbo.ccomm_ee_'+@suffix+'_'+@version+'
union all select ''GLSS'' as tbl, max(version) as version_max, max(effectivedate) as effe_max, max(releasedate) as release_max from calibressisdev.dbo.ccomm_glass_'+@suffix+'_'+@version+'
union all select ''GENP'' as tbl, max(version) as version_max, max(effectivedate) as effe_max, max(releasedate) as release_max from calibressisdev.dbo.ccomm_gp_'+@suffix+'_'+@version+'
union all select ''MACH'' as tbl, max(version) as version_max, max(effectivedate) as effe_max, max(releasedate) as release_max from calibressisdev.dbo.ccomm_machinery_'+@suffix+'_'+@version+'
union all select ''MONE'' as tbl, max(version) as version_max, max(effectivedate) as effe_max, max(releasedate) as release_max from calibressisdev.dbo.ccomm_money_'+@suffix+'_'+@version+'
union all select ''BURG'' as tbl, max(version) as version_max, max(effectivedate) as effe_max, max(releasedate) as release_max from calibressisdev.dbo.ccomm_theft_'+@suffix+'_'+@version+'
union all select ''GITT'' as tbl, max(version) as version_max, max(effectivedate) as effe_max, max(releasedate) as release_max from calibressisdev.dbo.ccomm_transit_'+@suffix+'_'+@version+'
union all select ''com_data'' as tbl, max(version) as version_max, max(effectivedate) as effe_max, max(releasedate) as release_max from calibressisdev.dbo.ccomm_data_'+@suffix+'_'+@version+'
union all select ''com_freecover'' as tbl, max(version) as version_max, max(effectivedate) as effe_max, max(releasedate) as release_max from calibressisdev.dbo.ccomm_freecovers_'+@suffix+'_'+@version+'
union all select ''com_scheme'' as tbl, max(version) as version_max, max(effectivedate) as effe_max, max(releasedate) as release_max from calibressisdev.dbo.ccomm_scheme_'+@suffix+'_'+@version+'
;'
;

EXEC(@VersionControl_Emulation_Step1 + @VersionControl_Emulation_Step2);

END
GO


