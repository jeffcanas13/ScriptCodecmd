@rem ******************************************************************
@rem * StartService:
@rem *
@rem *   Arguments: %1 = ENVIRONMENT (e.g. STGPRE)
@rem * *************************************************
@rem ******************************************************************
@echo off
if not "%~1"=="START" goto :normalStart
shift
shift
call %0 %1 %2 %3 %4 %5
exit /b %ERRORLEVEL%

:normalStart
setlocal
SET ENVCMD=%~dp0SETENV_%~1.cmd 
if not exist "%ENVCMD%" goto syntax
call "%ENVCMD%
@rem ******************************************************************
@rem * Sets Enviroment variables:
@rem *
@rem *     SVCNAME
@rem *     SVRROOT
@rem *     UPLDDIR
@rem *
@rem ******************************************************************

SET LGF=%~dp0StartService%RANDOM%.log
@rem call "%~0" "START" call :startService  2>&1 | wtee "%LGF%"
call :startService  2>&1 > "%LGF%"
IF %ERRORLEVEL% NEQ 0 (
    if not exist E:\CSC\Alerts\ServiceRestartError goto startDone
    call E:\CSC\Alerts\ServiceRestartError\SendMail PROCID %~1 "%LGF%" "%2" "%3"
)
:startDone
del /q "%LGF%" 2>&1 >NUL

goto done


@rem ******************************************************************
@rem * Start Service batch subroutine
@rem ******************************************************************
:startService
sc start %SVCNAME%
timeout 60 >NUL

SET SVCSTATE=UNK
for /F "tokens=1,2,3,4" %%a in ('sc query "%SVCNAME%"') do if "%%a" == "STATE" SET SVCSTATE=%%d
if "%SVCSTATE%" == "RUNNING" goto svcDone
if "%SVCSTATE%" == "START_PENDING" goto svcPending

echo *************************************************************************
echo *************************************************************************
echo *** ERROR: Service %SVCNAME% could not be started.
echo *************************************************************************
echo *************************************************************************
exit /B 1

:svcPending
echo *************************************************************************
echo * Service %SVCNAME% restarted with with START PENDING 
echo * after 60 seconds on %COMPUTERNAME%. 
echo *************************************************************************
exit /B 0

:svcDone
echo *************************************************************************
echo * Service %SVCNAME% start completed on %COMPUTERNAME%
echo *************************************************************************
exit /B 0

:syntax
call "%~dp0ENVLIST.cmd"
echo *************************************************************************
echo * 
echo * Syntax: StartService ENV
echo *         Where ENV = %ENVS%
echo *************************************************************************

:done
endlocal

