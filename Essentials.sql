set transaction isolation level read uncommitted
set nocount on

SELECT create_date ' last time the server is restarted' FROM sys.databases WHERE name = 'tempdb';
select database_id, name, is_parameterization_forced, is_query_store_on, compatibility_level,is_trustworthy_on, snapshot_isolation_state_desc,recovery_model_desc,
is_auto_create_stats_on, is_auto_update_stats_on, is_concat_null_yields_null_on, is_encrypted, two_digit_year_cutoff, containment_desc,
create_date
 from sys.databases
 WHERE [database_id] > 4


 -- space is used by the version store in tempdb 
SELECT DB_NAME(database_id) AS database_name,
  reserved_space_kb / 1024.0 AS version_store_mb
FROM sys.dm_tran_version_store_space_usage
WHERE reserved_space_kb > 0
ORDER BY 2 DESC;

/* Previous versions of SQL don't break it out per database: */
SELECT SUM (version_store_reserved_page_count)*8/1024.0  as version_store_mb
FROM tempdb.sys.dm_db_file_space_usage



--instant performance check 
exec [RmsAdmin].[dbo].[sp_BlitzFirst] --@help = 1 
				 @SinceStartup = 1 --go beyond 5 second snapshot
				 ,@expertmOde = 1
exec [RmsAdmin].[dbo].[sp_BlitzFirst] @Seconds = 60, @expertmOde = 1 -- wait ratio, db count, size, cpu utilization, memory grant
exec [RmsAdmin].[dbo].[sp_BlitzFirst] @SinceStartup = 1, @outputtype = 'Top10'

--***wait stats cheat sheet:
--CXPACKET/CXCONSUMER/LATCH_EX: queries going parallel to read a lot of data or do a lot of CPU work. Sort by CPU and by READS.
--						  set CTFP & MAXDOP to good defaults
--LCK%: locking, so look for long-running queries. Sort by DURATION, and look for the warning of "Long Running, Low CPU." That's probably a query being blocked.
	    -- look for aggressive indexes: sp_BlitzIndex @GetALLDatabases = 1
--PAGEIOLATCH: reading data pages that aren't cached in RAM. Sort by READS.
	    --	look for high-value missing indexes: sp_BlitzIndex @GetALLDatabases = 1
--RESOURCE_SEMAPHORE: queries can't get enough workspace memory to start running. Sort by MEMORY GRANT, although that isn't available in older versions of SQL.
--SOS_SCHEDULER_YIELD: CPU pressure, so sort by CPU.
--WRITELOG: writing to the transaction log for delete/update/insert (DUI) work. Sort by WRITES.

-- Login a table
--EXEC RmsAdmin.dbo.sp_BlitzFirst 
--  @OutputDatabaseName = 'DBADB', 
--  @OutputSchemaName = 'dbo', 
--  @OutputTableName = 'BlitzFirst',
--  @OutputTableNameFileStats = 'BlitzFirst_FileStats',
--  @OutputTableNamePerfmonStats = 'BlitzFirst_PerfmonStats',
--  @OutputTableNameWaitStats = 'BlitzFirst_WaitStats',
--  @OutputTableNameBlitzCache = 'BlitzCache',
--  @OutputTableNameBlitzWho = 'BlitzWho'
--  @OutputTableRetentionDays = 31; 
  
-- health check
exec [RmsAdmin].dbo.[sp_Blitz] 
	  @CheckProcedureCache = 1 /*top 20-50 resource-intensive cache plans and analyze them for common performance issues*/, 
	  @CheckUserDatabaseObjects = 0/* 1 if you control the db objects*/,
	  @IgnorePrioritiesAbove = 500 /*if you want a daily bulletin of the most important warnings, set 50 */,
	  --@CheckProcedureCacheFilter = 'CPU' --- | 'Reads' | 'Duration' | 'ExecCount'
	  @CheckServerInfo = 1 
exec [RmsAdmin].dbo.[sp_Blitz] @outputtype = 'MARKDOWN' -- notes for order

--exec [RmsAdmin].dbo.sp_WhoIsActive   
--		    @show_own_spid = 0
--		  , @get_task_info =2 /* 1 ie lightweight. task-based metrics : current wait stats, physical I/O, context switches, and blocker information*/
--		  , @get_avg_time = 1
--		  , @get_locks = 1
--		  --, @get_transaction_info = 1
--		  --, @delta_interval = 0 -- Interval in seconds to wait before doing the second data pull
--		  , @find_block_leaders =1
--		  , @show_sleeping_spids = 0 --1 sleeping with open transaction
--		  --, @get_plans = 1 
--		  , @sort_order = '[blocked_session_count] desc, [Used_Memory] desc, [open_tran_count] desc, [CPU] desc' 
--		  --, @destination_table = ''
--		  --, @output_column_list = '[col1][col2]...'


--exec [RmsAdmin].dbo.sp_WhoIsActive @get_locks = 1;
exec [RmsAdmin].dbo.sp_WhoIsActive  
		    @show_own_spid = 0
		  , @get_task_info =2 /* 1 ie lightweight. task-based metrics : current wait stats, physical I/O, context switches, and blocker information*/
		  , @get_avg_time = 1
		  , @get_locks = 1
		  --, @get_transaction_info = 1
		  --, @delta_interval = 5 -- Interval in seconds to wait before doing the second data pull
		  , @find_block_leaders =1
		  , @show_sleeping_spids = 0 --1 sleeping with open transaction
		  --, @get_plans = 1 
		  ,@get_additional_info = 1
		  , @sort_order = '[blocked_session_count] desc, [Used_Memory] desc, [CPU] desc, [open_tran_count] desc' 
		  --, @destination_table = ''
		  , @output_column_list = '[dd%][session_id][blocked_session_count][login_name][host_name][database_name][program_name][used_memory][cpu%][reads%][writes%][wait_info][physical%][sql_text][tasks][sql_command][tran_log%][temp%][context%][query_plan][locks][%]'-- '[col1][col2]...'



 -- index issues
EXEC [RmsAdmin].[dbo].sp_BlitzIndex @DatabaseName='MedRx' ,@Mode = 0
--index usage details
EXEC [RmsAdmin].[dbo].sp_BlitzIndex @DatabaseName='MedRx' -- or , @GetAllDatabases = 1
	   , @Mode = 2 
	   , @OutputDatabaseName = 'RmsAdmin' -- output won't work with other mode, has fillfactor
	   , @OutputSchemaName = 'dbo'
	   , @OutputTableName = 'BlitzIndex'
-- Missing indexes
SELECT max(captureDate) lastCapture from RmsAdmin.dbo.BlitzMissingIndex
EXEC [RmsAdmin].[dbo].sp_BlitzIndex @DatabaseName='MedRx' ,@Mode = 3
--on one table
EXEC RmsAdmin.dbo.sp_BlitzIndex @DatabaseName='MedRx', @SchemaName='dbo', @TableName='LockboxDocumentTrackingArchive';

--Dedupe
--Eliminate
--Add from missisng indexes
--Tune: indexes for specific queries from sp_BlitzCache
--Heaps:  create clustered indexes

--sp_BlitzCache: query to tune -- a plus if log when sp_BlitzFirst is run
EXEC [RmsAdmin].dbo.sp_BlitzCache ---is included when run Blitzfirst
  @OutputDatabaseName = 'RmsAdmin', 
  @OutputSchemaName = 'dbo', 
  @OutputTableName = 'BlitzCache'


--live activity checker - what�s really happening - Forget sp_Who and sp_Who2
exec [RmsAdmin].[dbo].sp_BlitzWho @ExpertMode = 1
exec [RmsAdmin].[dbo].sp_BlitzLock

--Look for # executions/min 
-- Query Type = "statement" easy to tune 

--chance last 60 min -- !!!ATTENTION TO 1 Plan Cache Information!!!
EXEC [RmsAdmin].dbo.sp_BlitzCache @MinutesBack = 60, @Top = 100,   @DatabaseName='Medrx'
		  --@StoredProcName = 'TR_ExtractProcedureOrRevenueCode' --0-- @DurationFilter = 5

--exec [RmsAdmin].dbo.sp_BlitzCache @OnlyQueryHashes = 0x53BCBB36510E6C00
----exec [RmsAdmin].dbo.sp_BlitzCache_new @help = 1

-- @SortOrder: "CPU", "Reads", "Writes", "Duration", "Executions", "Recent Compilations", "Memory Grant", "Spills".

EXEC [RmsAdmin].dbo.sp_BlitzCache @SortOrder = 'CPU',    @DatabaseName='Medrx' -- CXPACKET then sort by reads 
EXEC [RmsAdmin].dbo.sp_BlitzCache @SortOrder = 'CPU',    @DatabaseName='Medrx' -- SOS_SCHEDULER_YIELD
EXEC [RmsAdmin].dbo.sp_BlitzCache @SortOrder = 'READS',    @DatabaseName='Medrx' -- PAGEIOLATCH reading data pages not in RAM
EXEC [RmsAdmin].dbo.sp_BlitzCache @SortOrder = 'WRITES',    @DatabaseName='Medrx' -- WRITELOG
EXEC [RmsAdmin].dbo.sp_BlitzCache @SortOrder = 'DURATION',    @DatabaseName='Medrx' -- LCK% ie Look for "Long Running, Low CPU"
EXEC [RmsAdmin].dbo.sp_BlitzCache @SortOrder = 'MEMORY GRANT',    @DatabaseName='Medrx' -- RESOURCE_SEMAPHORE ie queries not enough workspace to start running

--***wait stats cheat sheet:
--CXPACKET/CXCONSUMER/LATCH_EX: queries going parallel to read a lot of data or do a lot of CPU work. Sort by CPU and by READS.
--						  set CTFP & MAXDOP to good defaults
--LCK%: locking, so look for long-running queries. Sort by DURATION, and look for the warning of "Long Running, Low CPU." That's probably a query being blocked.
	    -- look for aggressive indexes: sp_BlitzIndex @GetALLDatabases = 1
--PAGEIOLATCH: reading data pages that aren't cached in RAM. Sort by READS.
	    --	look for high-value missing indexes: sp_BlitzIndex @GetALLDatabases = 1
--RESOURCE_SEMAPHORE: queries can't get enough workspace memory to start running. Sort by MEMORY GRANT, although that isn't available in older versions of SQL.
--SOS_SCHEDULER_YIELD: CPU pressure, so sort by CPU.
--WRITELOG: writing to the transaction log for delete/update/insert (DUI) work. Sort by WRITES.

-- CHECK POWER BI DASHBORD AT 8am AND 5pm

 set transaction isolation level read uncommitted
set nocount on

-- study indexes on a table
exec sp_SQLskills_helpindex @objname= LockboxCHKAdjustments, @IncludeListOrdered = 1, @thresholdOfUnUsed = .019, @HasMeaning = 0
-- FK to know if we can disable or drop the index if any appaear enabled here, don't proceed
	           select  name FK_name, schema_name(fk.schema_id) + '.' + object_name(fk.parent_object_id) + '.' +col_name(fk.parent_object_id,fkc.parent_column_id) InColName,  object_name(fk.referenced_object_id) refTable ,
			 fk.is_disabled, fk.is_not_trusted, 
			 fk.delete_referential_action_desc d_action, fk.update_referential_action_desc u_action 
			 from sys.foreign_keys fk
			 join sys.foreign_key_columns fkc on fk.object_id = fkc.constraint_object_id
			 where --fk.is_disabled = 0 and 
			 object_name(fk.referenced_object_id) = parsename(quotename('LockboxCHKAdjustments'),1)
			 union all
			 select  name FK_name, schema_name(fk.schema_id) + '.' + object_name(fk.parent_object_id) + '.' +col_name(fk.parent_object_id,fkc.parent_column_id) InColName,  object_name(fk.referenced_object_id) refTable ,
			 fk.is_disabled, fk.is_not_trusted, 
			 fk.delete_referential_action_desc d_action, fk.update_referential_action_desc u_action 
			 from sys.foreign_keys fk
			 join sys.foreign_key_columns fkc on fk.object_id = fkc.constraint_object_id
			 where --fk.is_disabled = 0 and 
			 object_name(fk.parent_object_id) = parsename(quotename('LockboxCHKAdjustments'),1)
exec sp_SQLskills_ListIndexForConsolidation @ObjName = LockboxCHKAdjustments

EXEC sp_SQLskills_ListIndex  '[dbo].[LockboxDocumentTracking]'

exec sp_SQLskills_helpindex @objname= LockboxCHKAdjustments, @IncludeListOrdered = 1, @thresholdOfUnUsed = .019, @HasMeaning = 1
exec sp_SQLskills_helpindex @objname= Exceptions,  @indnameKey = 'IX_Exceptions_dtException'
exec sp_SQLskills_ListIndexForConsolidation @ObjName = Exceptions,  @KeysFilter = '[LbxID]'
exec sp_SQLskills_ListIndexForConsolidation @ObjName = Exceptions, @KeysFilter = '[flsid]' --- @KeysFilter = '[ProviderId]'
exec sp_SQLskills_ListIndexForConsolidation @ObjName = exceptions, @indnameKey ='[IX_Mbxbackfilehistory_Lbxid_inc_20220427]' , @isShowSampleQuery = 1
--exec sp_SQLskills_ListIndexForConsolidation @ObjName = exceptions, @excludeRatioReadWrite = .019, @KeysFilter = '[cdException]', @isShowSampleQuery = 1  

-- QUERY IN CACHE USING AN INDEX
SELECT TOP 20 'IX_Mbxbackfilehistory_Lbxid_inc_20220427' indname, querystats.execution_count, querystats.last_execution_time 
    , SUBSTRING(sqltext.text
		  , (querystats.statement_start_offset / 2) + 1
		  , (CASE querystats.statement_end_offset WHEN -1 THEN DATALENGTH(sqltext.text) 
			 ELSE querystats.statement_end_offset  END - querystats.statement_start_offset) / 2 + 1) AS sqltext
    , sqltext.text, querystats.execution_count, querystats.total_logical_reads, querystats.total_logical_writes 
    , sqltext.*
FROM sys.dm_exec_query_stats as querystats
CROSS APPLY sys.dm_exec_text_query_plan (querystats.plan_handle, querystats.statement_start_offset, querystats.statement_end_offset) as textplan
CROSS APPLY sys.dm_exec_sql_text(querystats.sql_handle) AS sqltext 
WHERE CHARINDEX('IX_Mbxbackfilehistory_Lbxid_inc_20220427', textplan.query_plan, 1)> 0



  
--  SELECT f.database_id, f.name, f.file_id, volume_mount_point
--, v.total_bytes/1000000000 as total_GigaBytes, v.available_bytes/1000000000 as FreeGigaBytes,Cast(f.size * 8. / 1024 AS DECIMAL(10,2)) AS Size  
--FROM sys.master_files AS f  
--CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.file_id) v  
--where f.database_id = 9


--DECLARE @today DATETIME,@db INT;

--SELECT @today = convert(DATETIME, convert(CHAR(10), GETDATE(), 110), 110)

----select * from [dbo].[RMSDaily_Storage]
--select Collection_Time, Drive, FreeSpace_GB, TotalSpace_GB, convert(smallint,100*(FreeSpace_GB / TotalSpace_GB)) as '% Free'
--    from [dbo].[RMSDaily_Storage] 
--where Collection_Time >= dateadd(yy,-1,getdate())
----and FreeSpace_GB = .75 * TotalSpace_GB
----and FreeSpace_GB = .50 * TotalSpace_GB
--order by Collection_Time


SELECT tab.TABLE_NAME,
    Col.Column_Name as 'PRIMARY KEY COLUMN'
FROM
    INFORMATION_SCHEMA.TABLE_CONSTRAINTS Tab,
    INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE Col
WHERE
    Col.Constraint_Name = Tab.Constraint_Name
    AND Col.Table_Name = Tab.Table_Name
    AND Constraint_Type = 'PRIMARY KEY'
    and (Tab.Table_Name like '%PaySplitIDRef%' or Col.Column_Name like '%PaySplitIDRef%')
order by tab.TABLE_NAME

--EXEC sp_MSforeachtable 'TRUNCATE TABLE ?'

EXEC sp_MSforeachdb N'USE [?]; SELECT DB_NAME()  SELECT * FROM SYS.tables WHERE NAME LIKE ''%RecordTypes%'' order by name;'

--preferred sp_ineachdb developed by Aaron Bertrand as an alternative to sp_MSforeachdb.
EXEC sp_ineachdb @command = N'SELECT DB_NAME()  SELECT * FROM SYS.tables WHERE NAME LIKE ''%RecordTypes%'' order by name;'

 

EXEC sp_MSforeachdb N'USE [?]; SELECT DB_NAME(); select distinct OBJECT_NAME(object_id) nom,name  
from sys.columns where name like ''%mbhid%'' order by nom'

EXEC sp_MSforeachdb N'USE [?]; SELECT DB_NAME(); 
SELECT TOP 50 st.text, qs.*
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
where st.text like ''%BlitzIndex%''
'

exec sp_helptext'PopulateLoaderState'
exec sp_helptext'sp_SQLskills_ListIndexForConsolidation'

select * from SystemReceiptDetail

EXEC dbo.sp_BlitzIndex @DatabaseName='MedRx', @SchemaName='dbo', @TableName='extractOutput';

exec sp_SQLskills_ListIndexForConsolidation  'dbo.extractOutput'  ---, '[StatusID]'


exec sp_SQLskills_helpindex extractOutput
--exec sp_SQLskills_finddupes HSBankingPartner
--exec sp_SQLskills_finddupes HSLockboxAccount


EXEC sp_SQLskills_ListIndex exceptions

select top 5 ExpectedIndexName from LockboxDocumentTracking
where ExpectedIndexName  is not null

--exec sp_SQLskills_ListIndexForConsolidation 'billingrevamp.billingtransactionrevamp', '[billingdate]'

--exec sp_SQLskills_ListIndexForConsolidation 'dbo.BankingPartner', '[id]'


--EXEC sp_SQLskills_ListIndex LockboxDocumentTracking




 