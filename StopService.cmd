@rem ******************************************************************
@rem * StopService:
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

SET LGF=%~dp0StopService%RANDOM%.log
@rem call "%~0" "START" call :stopService  2>&1 | wtee "%LGF%"
call :stopService  2>&1 > "%LGF%"
IF %ERRORLEVEL% NEQ 0 (
    if not exist E:\CSC\Alerts\ServiceRestartError goto startDone
    call E:\CSC\Alerts\ServiceRestartError\SendMail PROCID %~1 "%LGF%" "%2" "%3"
)
:startDone
del /q "%LGF%" 2>&1 >NUL

goto done


@rem ******************************************************************
@rem * Stop Service batch subroutine
@rem ******************************************************************
:startService

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
goto done

:ok3
echo *************************************************************************
echo * Service %SVCNAME% stop completed on %COMPUTERNAME%
echo *************************************************************************
exit /B 0

:syntax
call "%~dp0ENVLIST.cmd"
echo *************************************************************************
echo * Syntax: StopService ENV
echo *         Where ENV = %ENVS%
echo *************************************************************************

:done
endlocal
