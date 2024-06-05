USE [CalibreSSiSdev]
GO

/****** Object:  StoredProcedure [emula].[OM_BusPack_Emulation_Prep_B_Test]    Script Date: 4/06/2024 5:51:44 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO









CREATE procedure [emula].[OM_BusPack_Emulation_Prep_B_Test] 
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

exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS_TEST]
@in_tablename = ''dbo.ccomm_businessproperty_sicurve_'+@suffix+''',
@out_tablename = ''dbo.ccomm_businessproperty_sicurve_final'',
@clause = '''',
@version = '+@version+', 
@part_key = ''state
      ,type
      ,suminsuredfrom
      ,suminsuredto''


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
exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS_TEST]
@in_tablename = ''calibressisdev.dbo.ccomm_businessproperty_temp'',
@out_tablename = ''calibressisdev.dbo.ccomm_businessproperty_final'',
@clause = '''',
@version = '+@version+', 
@part_key = ''groupid
      ,code
      ,rangefield
      ,lowerfrom
	  ,upperto
	  ,relativitytype''

drop table if exists  calibressisdev.dbo.ccomm_businessproperty_temp



---- Update Occupation table


exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS_TEST]
@in_tablename = ''calibressisdev.dbo.ccomm_occupation_'+@suffix+''',
@out_tablename = ''calibressisdev.dbo.ccomm_occupation_final'',
@clause = '''',
@version = '+@version+', 
@part_key = ''calliden_code''



---- Update Excess table
exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS_TEST]
@in_tablename = ''calibressisdev.dbo.ccomm_excess_'+@suffix+''',
@out_tablename = ''calibressisdev.dbo.ccomm_excess_final'',
@clause = '''',
@version = '+@version+', 
@part_key = ''relativitytype
      ,state
	  ,excessvalue''
    


---- Update Location table
exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS_TEST]
@in_tablename = ''calibressisdev.dbo.ccomm_location_'+@suffix+''',
@out_tablename = ''calibressisdev.dbo.ccomm_location_final'',
@clause = '''',
@version = '+@version+', 
@part_key = ''locationindex''


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
exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS_TEST]
@in_tablename = ''calibressisdev.dbo.ccomm_liability_temp'',
@out_tablename = ''calibressisdev.dbo.ccomm_liability_final'',
@clause = '''',
@version = '+@version+', 
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
from calibressisdev.dbo.ccomm_liability_final
where groupid in (''PartTimeStaff'', ''FullTimeStaff'', ''CombinedStaff'') and CURRENT_FLAG = ''Yes'';

drop table if exists  calibressisdev.dbo.ccomm_liability_temp;



---- Update BI table
exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS_TEST]
@in_tablename = ''calibressisdev.dbo.ccomm_bi_'+@suffix+''',
@out_tablename = ''calibressisdev.dbo.ccomm_bi_final'',
@clause = '''',
@version = '+@version+', 
@part_key = ''code
      ,relativitytype''



---- Update Minimum table
exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS_TEST]
@in_tablename = ''calibressisdev.dbo.ccomm_minimum_'+@suffix+''',
@out_tablename = ''calibressisdev.dbo.ccomm_minimum_final'',
 @clause = '''',
 @version = '+@version+', 
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
exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS_TEST]
@in_tablename = ''calibressisdev.dbo.ccomm_ee_temp'',
@out_tablename = ''calibressisdev.dbo.ccomm_ee_final'',
 @clause = '''',
 @version = '+@version+', 
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
exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS_TEST]
@in_tablename = ''calibressisdev.dbo.ccomm_glass_temp'',
@out_tablename = ''calibressisdev.dbo.ccomm_glass_final'',
 @clause = '''',
 @version = '+@version+', 
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
 exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS_TEST]
@in_tablename = ''calibressisdev.dbo.ccomm_gp_temp'',
@out_tablename = ''calibressisdev.dbo.ccomm_gp_final'',
 @clause = '''',
 @version = '+@version+', 
 @part_key =''groupid
 ,code''





';


Set @VersionControl_Emulation_Step2 ='
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

-- Apply Current Flag
 exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS_TEST]
@in_tablename = ''calibressisdev.dbo.ccomm_machinery_temp'',
@out_tablename = ''calibressisdev.dbo.ccomm_machinery_final'',
 @clause = '''',
 @version = '+@version+', 
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
 exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS_TEST]
@in_tablename = ''calibressisdev.dbo.ccomm_money_temp'',
@out_tablename = ''calibressisdev.dbo.ccomm_money_final'',
 @clause = '''',
 @version = '+@version+', 
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
 exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS_TEST]
@in_tablename = ''calibressisdev.dbo.ccomm_theft_temp'',
@out_tablename = ''calibressisdev.dbo.ccomm_theft_final'',
 @clause = '''',
 @version = '+@version+', 
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
 exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS_TEST]
@in_tablename = ''calibressisdev.dbo.ccomm_transit_temp'',
@out_tablename = ''calibressisdev.dbo.ccomm_transit_final'',
 @clause = '''',
 @version = '+@version+', 
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
drop table if exists  calibressisdev.dbo.ccomm_data_temp;
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
 drop table if exists  calibressisdev.dbo.ccomm_data_temp2;
 exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS_TEST]
@in_tablename = ''calibressisdev.dbo.ccomm_data_temp'',
@out_tablename = ''calibressisdev.dbo.ccomm_data_temp2'',
 @clause = '''',
 @version = '+@version+', 
 @part_key =''groupid
 ,code
 ,text_property_a
 ,text_property_b
 ,text_property_c
 ,lowerfrom
 ,upperto''
 
drop table if exists calibressisdev.dbo.ccomm_data_final;
Select 
	groupid
	, code
	, text_property_a
	, text_property_b
	, text_property_c
	, int_property_a
	, int_property_b
	, int_property_c
	, lowerfrom
	, upperto
	, version
	, effectivedate
	, Case When groupid like ''OSQ%'' Then LEAD(effectivedate,1,''9999-12-31'') over (partition by groupid, code, lowerfrom, upperto order by effectivedate asc)
		else enddate end as enddate
	, releasedate
	, case when groupid like ''OSQ%'' and LEAD(effectivedate,1,''9999-12-31'') over (partition by groupid, code, lowerfrom, upperto order by effectivedate asc) = ''9999-12-31'' and version = '+ @version +' then ''YES''
		when groupid like ''OSQ%'' and LEAD(effectivedate,1,''9999-12-31'') over (partition by groupid, code, lowerfrom, upperto order by effectivedate asc) = ''9999-12-31'' and version <> '+ @version +' then ''YES''
		when groupid like ''OSQ%'' and LEAD(effectivedate,1,''9999-12-31'') over (partition by groupid, code, lowerfrom, upperto order by effectivedate asc) <> ''9999-12-31'' and version = '+ @version +' then ''YES''
		when groupid like ''OSQ%'' and LEAD(effectivedate,1,''9999-12-31'') over (partition by groupid, code, lowerfrom, upperto order by effectivedate asc) <> ''9999-12-31'' and version <> '+ @version +' then ''NO''
		else current_flag end as CURRENT_FLAG 
into calibressisdev.dbo.ccomm_data_final
from calibressisdev.dbo.ccomm_data_temp2
;





 ---- Update Freecover Table
exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS_TEST]
@in_tablename = ''calibressisdev.dbo.ccomm_freecovers_'+@suffix+''',
@out_tablename = ''calibressisdev.dbo.ccomm_freecovers_final'',
 @clause = '''',
 @version = '+@version+', 
 @part_key =''section
 ,covertype,product''
 

 ---- Update Scheme Table
 exec Calibressisdev.dbo.[EMULA_UPDATE_SDP_REL_TABLES_IMPACT_ANALYSIS_TEST]
@in_tablename = ''calibressisdev.dbo.ccomm_scheme_'+@suffix+''',
@out_tablename = ''calibressisdev.dbo.ccomm_scheme_final'',
 @clause = '''',
 @version = '+@version+', 
 @part_key =''schemeid
 ,relativitytype''
 

 
;'
;

EXEC(@VersionControl_Emulation_Step1 + @VersionControl_Emulation_Step2);

END
GO


