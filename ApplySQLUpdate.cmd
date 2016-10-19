@echo off
@rem ******************************************************************
@rem * ExcecSQL:
@rem *
@rem *   Arguments: %1 = ENVIRONMENT (e.g. STGPRE)
@rem * *************************************************
@rem * Perform a code move for SQL database.
@rem ******************************************************************
if "%CMWORK%" == "" goto invalidstart

echo *************************************************************************
echo *************************************************************************
echo * Begin SQL Code Move for %1
echo *      Code Move: %CODEMOVENUM%  Server: %COMPUTERNAME%
echo *************************************************************************
echo *************************************************************************

echo *************************************************************************
echo * Unzipping SQL.zip files to: "%CMWORK%"
echo *************************************************************************
cd /d "%CMWORK%"
if ERRORLEVEL 1 (
    SET CMERROR=true
    SET CMERRORDESC=Can't change directory to Code Move Work: %CMWORK%
    GOTO errorexit
)
unzip -j SQL.zip
if ERRORLEVEL 1 (
    SET CMERROR=true
    SET CMERRORDESC=Error unzipping SQL.zip file to Code Move Work: %CMWORK%
    GOTO errorexit
)

echo *************************************************************************
echo * Backing up databases before code move
echo *************************************************************************
call "%CMHOME%\SQLBackupDB"

@rem Set error env variables returned from batch call 
for /f "delims=" %%i in (%CMVarSetFile%) do (
    SET %%i
)

if %CMERROR% == true (
    GOTO errorexit
)

echo *************************************************************************
echo * Executing SQL Batch File: SQLBatch.bat
echo *************************************************************************
if NOT exist "SQLBatch.bat" (
    SET CMERROR=true
    SET CMERRORDESC=SQL Batch execution file: SQLBatch.bat does not exist in: %CMWORK%
    GOTO errorexit
)

@echo off
SET SQLBATCH_LOG=%CMWORK%\SQLBatch.log
call SQLBatch.bat >> %SQLBATCH_LOG%

@rem Set error env variables returned from batch call 
for /f "delims=" %%i in (%CMVarSetFile%) do SET %%i

@echo off
powershell "& {(Get-Content $env:SQLBATCH_LOG)|Foreach-Object {$_ -replace [regex]::escape($env:CMUPass), '######'} | Set-Content ($env:SQLBATCH_LOG+\".\"+(get-date).toString('yyyyMMddhhmmss')+\".log\")}"
@del %SQLBATCH_LOG%
TYPE "%SQLBATCH_LOG%*"

if %CMERROR% == true (
    GOTO errorexit
)

goto done


:invalidstart
call ENVLIST.cmd
echo *************************************************************************
echo * Error: This program must be started by the CodeMoveSQL command file.
echo * Syntax: CodeMove ENV
echo *         Where ENV = %ENVS%
echo *************************************************************************
goto :exit

:errorexit
cd "%CMHOME%"
echo *************************************************************************
echo *************************************************************************
echo * Error Description: %CMERRORDESC%
echo *************************************************************************
echo * ERROR: SQL Code Move Job Complete with Errors for %1
echo *      Code Move: %CODEMOVENUM%  Server: %COMPUTERNAME%
echo *************************************************************************
echo *************************************************************************
goto :exit

:done
cd %CMHOME%
echo *************************************************************************
echo *************************************************************************
echo * SQL Code Move Job Complete for %1
echo *      Code Move: %CODEMOVENUM%  Server: %COMPUTERNAME%
echo *************************************************************************
echo *************************************************************************

:exit
if "%CMVarSetFile%" == "" goto :EOF
@echo CMERROR=%CMERROR%>%CMVarSetFile%
@echo CMERRORDESC=%CMERRORDESC%>>%CMVarSetFile%
