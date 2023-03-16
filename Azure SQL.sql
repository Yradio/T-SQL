--details space used
EXEC sp_spaceused @oneresultset = 1


SELECT Edition = DATABASEPROPERTYEX('MyDatabase', 'EDITION'),
        ServiceObjective = DATABASEPROPERTYEX('MyDatabase', 'ServiceObjective'),
        MaxSizeInBytes =  DATABASEPROPERTYEX('MyDatabase', 'MaxSizeInBytes');

-- Modifies certain configuration options of a database.
--https://learn.microsoft.com/en-us/sql/t-sql/statements/alter-database-transact-sql?view=azuresqldb-current&preserve-view=true&tabs=sqlpool
--alter max_size not sure if size itself can be resize
--ALTER DATABASE [RemitHub_Production] MODIFY (EDITION = 'Standard', MAXSIZE = 1024GB, SERVICE_OBJECTIVE = 'S7');



--Resource limits for single databases using the DTU purchasing model
https://learn.microsoft.com/en-us/azure/azure-sql/database/resource-limits-dtu-single-databases?view=azuresql


--Run Scheduled Jobs in Azure SQL Databases
-- https://www.sqlservercentral.com/articles/how-to-run-scheduled-jobs-in-azure-sql-databases
1 - create the job in local instance and its SQL Agent
2 - use sqlcmd or powershell script
3 - sqlcmd - U daniel -d sqlcentralazure -S sqlservercentralserver.database.windows.net -P "YourAzurePassword" -i c:\script\todaysales.sql -o c:\script\azureoutput.txt

--automate tasks using elastic jobs
-- https://learn.microsoft.com/en-us/azure/azure-sql/database/job-automation-overview?view=azuresql
