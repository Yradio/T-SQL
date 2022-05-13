-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-query-profiles-transact-sql?view=sql-server-ver15

-- run with before the query
SET STATISTICS PROFILE ON;  
GO  

-- run in other session

SELECT node_id,physical_operator_name, SUM(row_count) row_count, 
  SUM(estimate_row_count) AS estimate_row_count, 
  CAST(SUM(row_count)*100 AS float)/SUM(estimate_row_count)  
FROM sys.dm_exec_query_profiles   
WHERE session_id=1508
GROUP BY node_id,physical_operator_name  
ORDER BY node_id; 


SELECT session_id,
sp.cmd,
sp.hostname,
db.name,
sp.last_batch,
node_id,
physical_operator_name,
SUM(row_count) row_count,
SUM(estimate_row_count) AS estimate_row_count,
CAST(SUM(row_count)*100 AS float)/SUM(estimate_row_count) as EST_COMPLETE_PERCENT
FROM sys.dm_exec_query_profiles eqp
join sys.sysprocesses sp on sp.spid=eqp.session_id
join sys.databases db on db.database_id=sp.dbid
WHERE session_id=1508
GROUP BY session_id, node_id, physical_operator_name, sp.cmd, sp.hostname, db.name, sp.last_batch
ORDER BY session_id, node_id desc;