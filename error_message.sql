
https://learn.microsoft.com/en-us/sql/t-sql/language-elements/raiserror-transact-sql?view=sql-server-ver16

EXEC master..sp_addmessage @msgnum = 50057, @severity = 16, 
		@msgtext  = 'Cannot delete Note Reference Data that is being used.'
		
		
RAISERROR (N'This is message %s %d.', -- Message text. the above link contains the los of type
           10, -- Severity,
           1, -- State,
           N'number', -- First argument.
           5); -- Second argument.
-- The message text returned is: This is message number 5.
GO		



-- You can specify -1 to return the severity value associated with the error as shown in the following example.
-- shown in the following example.
RAISERROR (15600, -1, -1, 'mysp_CreateCustomer');


--Logs the error in the error log and the application log for the instance
RAISERROR(N'Oops! No, don''t just hit F5. Run these demos one at a time.', 20, 1) WITH LOG;
GO