@rem ******************************************************************
@rem * RestartService:
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

SET LGF=%~dp0RestartService%RANDOM%.log
@rem call "%~0" "START" :restartService  2>&1 | wtee "%LGF%"
call :restartService  2>&1 > "%LGF%"
if ERRORLEVEL 1 (
    if not exist E:\CSC\Alerts\ServiceRestartError goto restartDone
    call E:\CSC\Alerts\ServiceRestartError\SendMail PROCID %~1 "%LGF%" "%2" "%3"
    goto restartDone
)
if not exist E:\CSC\Alerts\ServiceRestart goto restartDone
call E:\CSC\Alerts\ServiceRestart\SendMail PROCID %~1 "%LGF%" "%2" "%3"

:restartDone
del /q "%LGF%" 2>&1 >NUL

goto done


@rem ******************************************************************
@rem * Restart Service batch subroutine
@rem ******************************************************************
:restartService

SET SVCSTATE=UNK
for /F "tokens=1,2,3,4" %%a in ('sc query "%SVCNAME%"') do if "%%a" == "STATE" SET SVCSTATE=%%d
if "%SVCSTATE%" == "RUNNING" goto stopsvc
if "%SVCSTATE%" == "STOP_PENDING" goto stopstartpending1
if "%SVCSTATE%" == "START_PENDING" goto stopstartpending1
echo *************************************************************************
echo * Service %SVCNAME% already stopped.
echo *************************************************************************
goto ok3

:stopstartpending1
SET CTR=20
:stopstartpending2
SET /A CTR=%CTR% - 1
echo *********** In Stop/Start Pending Check: %CTR% ************
if %CTR% == 0 goto stopsvc
timeout 10 >NUL
for /F "tokens=1,2,3,4" %%a in ('sc query "%SVCNAME%"') do if "%%a" == "STATE" SET SVCSTATE=%%d
if "%SVCSTATE%" == "STOP_PENDING" goto stopstartpending2
if "%SVCSTATE%" == "START_PENDING" goto stopstartpending2
if "%SVCSTATE%" == "STOPPED" goto ok3

:stopsvc
echo *************************************************************************
echo * Stopping Service %SVCNAME%
echo *************************************************************************
sc stop %SVCNAME%
if errorlevel 1 goto stopsvcerr
for /F "tokens=1,2,3,4" %%a in ('sc query "%SVCNAME%"') do if "%%a" == "STATE" SET SVCSTATE=%%d
if "%SVCSTATE%" == "STOPPED" goto ok3
:stoppending1
SET CTR=20
:stoppending2
SET /A CTR=%CTR% - 1
echo *********** Service Stopping Check: %CTR% ************
if %CTR% == 0 goto stopsvcerr
timeout 10 >NUL
for /F "tokens=1,2,3,4" %%a in ('sc query "%SVCNAME%"') do if "%%a" == "STATE" SET SVCSTATE=%%d
if "%SVCSTATE%" == "STOPPED" goto ok3
if "%SVCSTATE%" == "STOP_PENDING" goto stoppending2

:stopsvcerr
echo *************************************************************************
echo *************************************************************************
echo *** ERROR: Service %SVCNAME% could not be stopped.
echo *************************************************************************
echo *************************************************************************
exit /B 1

:ok3
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
echo * Service %SVCNAME% restart completed on %COMPUTERNAME%
echo *************************************************************************
exit /B 0

:syntax
call "%~dp0ENVLIST.cmd"
echo *************************************************************************
echo * Syntax: RestartService ENV
echo *         Where ENV = %ENVS%
echo *************************************************************************

:done
endlocal
