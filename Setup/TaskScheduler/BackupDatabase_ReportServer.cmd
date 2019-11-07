sqlcmd -E -d SpravaZmluv -Q "EXEC [dbo].[BackupDatabase] 'ReportServer'"
sqlcmd -E -d SpravaZmluv -Q "EXEC [dbo].[BackupDatabase] 'ReportServerTempDB'"