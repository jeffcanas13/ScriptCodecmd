@echo off
@rem ******************************************************************
@rem ******************************************************************
@rem * SQLBackupDB:
@rem *
@rem * Backup Databases before a code move
@rem * *************************************************
@rem * Preset environment variables:
@rem *     BACKUPLOC   = Relative backup path
@rem *     BACKUPDB1   = Backup Database 1
@rem *     BACKUPDB2   = Backup Database 2
@rem *     CMENV       = Code Move Environment (e.g. STGSQL)
@rem *     CMUName     = Database User Name
@rem *     CMUPass     = Database User Password
@rem *     CODEMOVENUM = Code Move Number
@rem *     CODEMOVESFX = Code Move Suffix 
@rem *     MOVEDIR     = Code Move Directory Name
@rem *     MOVEPATH    = Code Move full directory path
@rem *     CMServer    = Code Move full directory path
@rem *     CMERROR     = Boolean to indicate error
@rem *     CMERRORDESC = Error Description
@rem *     CMVarSetFile= Temporary file to pass error return variables
@rem ******************************************************************
@rem ******************************************************************
SET CMSFX=-%CMENV%
if NOT "%CODEMOVESFX%" == "" (
    SET CMSFX=%CMSFX%%CODEMOVESFX%
)

:dbchk1
if "%BACKUPDB1" == "" goto dbchk2
sqlcmd -U %CMUName% -P %CMUPass% -S %CMServer% -d %BACKUPDB1%  -i  %CMHOME%\SQLBackupDB.sql  -v Fsit=%CODEMOVENUM% -v BackupLoc=%BACKUPLOC% -v CMSfx=%CMSFX% -v Db=%BACKUPDB1% -V 11 -e >> %CMWORK%\SQLBackupDb.log
@if ERRORLEVEL 1 (
   SET CMERROR=true
   SET CMERRORDESC=Backup SQL Command Execution Error: SQLBackupDB.sql
   GOTO :done
)

:dbchk2
if "%BACKUPDB2" == "" goto done
sqlcmd -U %CMUName% -P %CMUPass% -S %CMServer% -d %BACKUPDB2%  -i  %CMHOME%\SQLBackupDB.sql  -v Fsit=%CODEMOVENUM% -v BackupLoc=%BACKUPLOC% -v CMSfx=%CMSFX% -v Db=%BACKUPDB2% -V 11 -e >> %CMWORK%\SQLBackupDb.log
@if ERRORLEVEL 1 (
   SET CMERROR=true
   SET CMERRORDESC=Backup SQL Command Execution Error: SQLBackupDB.sql
   GOTO :done
)

:done
echo *****************************************************
type %CMWORK%\SQLBackupDb.log
echo *****************************************************

:exit
if "%CMVarSetFile%" == "" goto :EOF
@echo CMERROR=%CMERROR%>%CMVarSetFile%
@echo CMERRORDESC=%CMERRORDESC%>>%CMVarSetFile%

