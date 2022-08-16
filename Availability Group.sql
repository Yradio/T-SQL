CREATE AVAIBILITY GROUP <ag_name>
FOR DATABASE <db1>, <db2>
REPLICA ON 
		<'COMPUTER01'> WITH (
			 ENDPOINT_URL = 'TCP://COMPUTER01:5022',  
			 AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,  
			 FAILOVER_MODE = AUTOMATIC)
		,
		<'COMPUTER02'> WITH (
			 ENDPOINT_URL = 'TCP://COMPUTER02:5022',  
			 AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
			 FAILOVER_MODE = MANUAL)
			 
GO

ALTER AVAILABILITY GROUP <ag_name>
  ADD LISTENER 'MyAgListenerIvP6' ( WITH IP ( ('2001:db88:f0:f00f::cf3c'),('2001:4898:e0:f213::4ce2') ) , PORT = 60173 );   
GO  			 