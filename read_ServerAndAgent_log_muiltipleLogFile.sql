--https://www.mssqltips.com/sqlservertip/3135/search-multiple-sql-server-error-logs-at-the-same-time/

--*********Description: search some texts through SQL Server & Agent logs from the last 7 days

-- last update 7/10/2023 By Monktar Bello: 
--						  used only sys.xp_enumerrorlogs
--						  search different texts
--						  enabled search from Agent log or SQL Server Log

SET NOCOUNT ON

DECLARE @maxLog      INT,
        @searchStr   VARCHAR(256),
        @startDate   DATETIME;

declare @searchStrFail VARCHAR(256) = 'fail';
-- declare @searchStrFail VARCHAR(256) = ''; !!!!!!!!!****Empty string search returns all from log
declare @searchStrError VARCHAR(256) = 'error';
declare @searchStrWarning VARCHAR(256) = 'warning';
declare @searchStrPort VARCHAR(256) = 'Server is listening on';

--parameters
SELECT @startDate = dateadd(dd,-7,GETDATE());
declare @LogType  int = 1 -- 1 ServerLog - 2 AgentLog


DECLARE @errorLogs   TABLE (
    LogID    INT,
    LogDate  DATETIME,
    LogFileSizeBytes  BIGINT   );

DECLARE @logData      TABLE (
    LogDate     DATETIME,
    ProcInfo    VARCHAR(64),
    LogText     VARCHAR(MAX)   );


SELECT iif(@logType = 1, 'SQL Server Logs','SQL Agent Logs') as LogType


-- get log files
INSERT INTO @errorLogs 
EXEC sys.xp_enumerrorlogs @LogType;

--locations
--SELECT SERVERPROPERTY('ErrorLogFileName') AS 'SQL Error log file location';
--EXEC msdb.dbo.sp_get_sqlagent_properties

-- errors log files
select logId, LogDate, LogFileSizeBytes/1024 as LogFileSizeKiloBytes  from @errorLogs order by LogID

SELECT @maxLog = max(LogID)
FROM @errorLogs
--WHERE [LogDate] <= @startDate
--ORDER BY [LogDate] DESC;
select @maxLog 'maxlog'

WHILE @maxLog >= 0
BEGIN
    INSERT INTO @logData
    EXEC sys.sp_readerrorlog @maxLog, @LogType, @searchStrFail --optional @startDate, @EndDate 
    
    INSERT INTO @logData
    EXEC sys.sp_readerrorlog @maxLog, @LogType, @searchStrError --optional @startDate, @EndDate 

    INSERT INTO @logData
    EXEC sys.sp_readerrorlog @maxLog, @LogType, @searchStrWarning --optional @startDate, @EndDate 

     INSERT INTO @logData
    EXEC sys.sp_readerrorlog @maxLog, @LogType, @searchStrPort --optional @startDate, @EndDate 

    SET @maxLog = @maxLog - 1;
END

SELECT [LogDate], [LogText]
FROM @logData
--WHERE [LogDate] >= @startDate
ORDER BY [LogDate] DESC;
