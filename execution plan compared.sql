--your execution plan attributes to know which settings is used by your execution plan
--this is beside comparing the graph in ssms


--https://www.mssqltips.com/sqlservertip/4318/sql-server-stored-procedure-runs-fast-in-ssms-and-slow-in-application/


--get the plan_handle for next query
select o.object_id, OBJECT_NAME(o.object_id), s.plan_handle, h.query_plan 
from sys.objects o 
inner join sys.dm_exec_procedure_stats s on o.object_id = s.object_id
cross apply sys.dm_exec_query_plan(s.plan_handle) h
where o.object_id = object_id('sp_UpdateDocumentFlowLayout')

--https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-plan-attributes-transact-sql?redirectedfrom=MSDN&view=sql-server-ver15

--provide 2 differents plan_handle to see the aatributes particularly  'set_options'
select * from sys.dm_exec_plan_attributes (0x05000600D5E4C86610DE2F090200000001000000000000000000000000000000000000000000000000000000)
select * from sys.dm_exec_plan_attributes (0x05000600D5E4C8661095B5670200000001000000000000000000000000000000000000000000000000000000)

--Evaluating 'set_options'
--use the table in 
--https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-plan-attributes-transact-sql?redirectedfrom=MSDN&view=sql-server-ver15
--To translate the value returned in set_options to the options with which the plan was compiled, 
--subtract the values from the set_options value, starting with the largest possible value, until you reach 0. 
--Each value you subtract corresponds to an option that was used in the query plan. 
--For example, if the value in set_options is 251, the options the plan was compiled with are 
--ANSI_NULL_DFLT_ON (128), QUOTED_IDENTIFIER (64), ANSI_NULLS(32), ANSI_WARNINGS (16), CONCAT_NULL_YIELDS_NULL (8), Parallel Plan(2) and ANSI_PADDING (1).