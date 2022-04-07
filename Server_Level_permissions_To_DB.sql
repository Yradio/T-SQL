--some credits to http://whoisactive.com/docs/28_access/ and https://www.sommarskog.se/grantperm.html#serverlevel
-- https://docs.microsoft.com/en-us/sql/t-sql/statements/create-certificate-transact-sql?view=sql-server-ver15
--sql server 2017 compati 140


--**1 Create the certificate in the user database.
use DBA_DB
go
CREATE CERTIFICATE Certi_ForServerPermissions AUTHORIZATION dbo
ENCRYPTION BY PASSWORD = 'P@ssword!P@mizi'
WITH SUBJECT = 'For Non Admin',
EXPIRY_DATE = '9999-12-31'
GO

--**2 Sign the procedure.
use DBA_DB
go
ADD SIGNATURE TO dbo.sp_WhoIsActive
BY CERTIFICATE Certi_ForServerPermissions
WITH PASSWORD = 'P@ssword!P@mizi'
GO

--**3 Drop the private key.
--	   (safe to avoid anyone to use the pass to sign others thing) because of this, 
--	   drop the signature and the certificate and create a new certificate then resign the proc after alter the proc
ALTER CERTIFICATE Certi_ForServerPermissions REMOVE PRIVATE KEY

--**4 Copy the certificate to master.
use DBA_DB
GO
DECLARE @public_key varbinary(MAX), @sql nvarchar(MAX);

SET @public_key = certencoded(cert_id('Certi_ForServerPermissions'));
SET @sql = 'CREATE CERTIFICATE Certi_ForServerPermissions FROM BINARY = ' + convert(varchar(MAX), @public_key, 1);

USE master
--PRINT 
EXEC(@sql)


--**5 Create a login from the certificate.
CREATE LOGIN User_ForServerPermissions FROM CERTIFICATE Certi_ForServerPermissions


--**6 Grant the certificate login the required permissions.
GRANT VIEW SERVER STATE TO User_ForServerPermissions


--**7 please clean after yourself
DROP LOGIN User_ForServerPermissions
use master 
DROP CERTIFICATE Certi_ForServerPermissions
use DBA_DB
drop signature FROM dbo.sp_WhoIsActive BY  CERTIFICATE Certi_ForServerPermissions
DROP CERTIFICATE Certi_ForServerPermissions
--drop user if exists testbello -- if exists IN tsql in version 2016 and up
--DROP PROC IF EXISTS dbo.sp_WhoIsActive
