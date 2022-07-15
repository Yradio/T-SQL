-- inspired by  https://www.datavail.com/blog/how-to-restore-your-backups-from-striped-backup-files/

--date 7/15/2022
need work to combine with my ola-restore  script. the latter care more a single file

-- Generate TSQL script to restore the single and multi-file backups

-- ****************************************************************************

-- Copyright � 2016 by JP Chen of DatAvail Corporation

-- This script is free for non-commercial purposes with no warranties.

-- ****************************************************************************

SELECT 
--SERVERPROPERTY('SERVERNAME') as InstanceName

--,bs.database_name as DatabaseName

--,bmf.physical_device_name as BackupPath

--,bs.backup_start_date as BackupStartDate

--,bs.backup_finish_date as BackupFinishDate

--,
bmf.physical_device_name, bs.backup_finish_date as BackupFinishDate,
CASE

       WHEN SUBSTRING(bmf.physical_device_name, LEN(REVERSE(bmf.physical_device_name)) - 5, 1) <> '_' THEN 'RESTORE DATABASE ' +bs.database_name+ ' FROM DISK = ''' + bmf.physical_device_name + ''' WITH STATS = 10, REPLACE, NORECOVERY'

       WHEN bmf.physical_device_name LIKE '%_01%.bak' THEN 'RESTORE DATABASE ' +bs.database_name+ ' FROM DISK = ''' + bmf.physical_device_name + ''','

       WHEN bmf.physical_device_name LIKE '%_2.bak' THEN 'DISK = ''' + bmf.physical_device_name + ''','

       WHEN bmf.physical_device_name LIKE '%_3.bak' THEN 'DISK = ''' + bmf.physical_device_name + ''','

       WHEN bmf.physical_device_name LIKE '%_4.bak' THEN 'DISK = ''' + bmf.physical_device_name + ''' WITH STATS = 10, REPLACE, RECOVERY'

END AS RestoreTSQL

FROM msdb.dbo.backupset bs JOIN msdb.dbo.backupmediafamily bmf

       ON bs.media_set_id = bmf.media_set_id

WHERE bs.type = 'D' -- D = Full, I = Differential, L = Log, F = File or filegroup

AND bs.database_name IN('MedRx') -- specify your databases here

ORDER BY BackupFinishDate DESC


-- log

SELECT 
--SERVERPROPERTY('SERVERNAME') as InstanceName

--,bs.database_name as DatabaseName

--,bmf.physical_device_name as BackupPath

--,bs.backup_start_date as BackupStartDate

--,bs.backup_finish_date as BackupFinishDate

--,
bmf.physical_device_name, bs.backup_finish_date as BackupFinishDate,
CASE

       WHEN SUBSTRING(bmf.physical_device_name, LEN(REVERSE(bmf.physical_device_name)) - 5, 1) <> '_' THEN 'RESTORE DATABASE ' +bs.database_name+ ' FROM DISK = ''' + bmf.physical_device_name + ''' WITH STATS = 10, REPLACE, NORECOVERY'

       WHEN bmf.physical_device_name LIKE '%_01%.bak' THEN 'RESTORE DATABASE ' +bs.database_name+ ' FROM DISK = ''' + bmf.physical_device_name + ''','

       WHEN bmf.physical_device_name LIKE '%_2.bak' THEN 'DISK = ''' + bmf.physical_device_name + ''','

       WHEN bmf.physical_device_name LIKE '%_3.bak' THEN 'DISK = ''' + bmf.physical_device_name + ''','

       WHEN bmf.physical_device_name LIKE '%_4.bak' THEN 'DISK = ''' + bmf.physical_device_name + ''' WITH STATS = 10, REPLACE, RECOVERY'

END AS RestoreTSQL

FROM msdb.dbo.backupset bs JOIN msdb.dbo.backupmediafamily bmf

       ON bs.media_set_id = bmf.media_set_id

WHERE bs.type = 'L' -- D = Full, I = Differential, L = Log, F = File or filegroup

AND bs.database_name IN('MedRx') -- specify your databases here

ORDER BY BackupFinishDate DESC