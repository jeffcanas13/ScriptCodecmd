@echo off
@rem ******************************************************************
@rem * ApplyCodeUpdates:
@rem *
@rem *   Arguments: %1 = ENVIRONMENT (e.g. STGPRE)
@rem *   Arguments: %2 = Code Move directory (e.g. MoveForm123456)
@rem * *************************************************
@rem * Perform a code move for Tomcat or tcServer.
@rem * This will call a command file to set the code move environment
@rem * variabless. The %1 argument is the name of the SETENV_%1.cmd
@rem * file to be called. It will stop the application server service,
@rem * Loop through any .war files in the upload directory and back
@rem * up the existing deployed war and deploy the new war file to the
@rem * directory. After all war files are processed this command file
@rem * will restart the application server service.
@rem ******************************************************************
if "%CMWORK%" == "" goto invalidstart

@if exist "%UPLDDIR%" goto ok1
echo *************************************************************************
echo * Error: Uplodad directory "%UPLDDIR%"
echo * does not exist. Operation cannot proceed.
echo *************************************************************************
goto done

:ok1
if "%UPLDDIR%" == "%CMWORK%" goto ok1b
SET ACUMOVEDIR=%~2
@if exist "%UPLDDIR%\%ACUMOVEDIR%" goto ok1b
echo *************************************************************************
echo * Error: Uplodad move form directory "%UPLDDIR%\%ACUMOVEDIR%"
echo * does not exist. Operation cannot proceed.
echo *************************************************************************
goto done

:ok1b

@if exist "%SVRROOT%" goto ok2
echo *************************************************************************
echo * Error: tcServer/Tomcat root directory "%SVRROOT%"
echo * does not exist. Operation cannot proceed.
echo *************************************************************************
goto done
:ok2

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
SET CTR=10
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
SET CTR=10
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
echo * Error stopping service %SVCNAME%
echo * The war file may not be successfully deployed if the service
echo * is not stopped. If the service is already stopped then this 
echo * warning can be ignored.
echo *************************************************************************
SET CMERROR=true
SET CMERRORDESC=Error stopping service %SVCNAME% - Code Move wasn't started.
timeout 60 >NUL
goto done

:ok3
if not "%UPLDDIR%" == "%CMWORK%" goto noftp
echo *************************************************************************
echo * Code move for: %CMWORK%
echo *************************************************************************
cd /D %CMWORK%
for %%I in (*.war) do (
    call "%CMHOME%\DeployWar" %%~nxI "%CMWORK%" %%~nI "%CMWORK%" "%SVRROOT%"
    @rem Set error env variables returned from batch call 
    for /f "delims=" %%i in (%CMVarSetFile%) do SET %%i
)
goto  done


:noftp
if not "%ACUMOVEDIR%" == "" goto moveformdir
cd /D %UPLDDIR%
for %%I in (*.war) do (
    call "%CMHOME%\DeployWar" %%~nxI %UPLDDIR% %%~nI %CMWORK% "%SVRROOT%"
    @rem Set error env variables returned from batch call 
    for /f "delims=" %%i in (%CMVarSetFile%) do SET %%i
)

goto  done

:moveformdir
cd /D %UPLDDIR%\%ACUMOVEDIR%
for %%I in (*.war) do (
    call "%CMHOME%\DeployWar" %%~nxI %UPLDDIR%\%ACUMOVEDIR% %%~nI %CMWORK% "%SVRROOT%"
    @rem Set error env variables returned from batch call 
    for /f "delims=" %%i in (%CMVarSetFile%) do SET %%i
)

cd ..
rd %ACUMOVEDIR%
goto  done

:invalidstart
call ENVLIST.cmd
echo *************************************************************************
echo * Error: This program must be started by the CodeMove command file.
echo * Syntax: CodeMove ENV
echo *         Where ENV = %ENVS%
echo *************************************************************************
goto :EOF

:syntax
call ENVLIST.cmd
echo *************************************************************************
echo * Syntax: CodeMove ENV
echo *         Where ENV = %ENVS%
echo *************************************************************************
goto :EOF

:done
echo *************************************************************************
echo * Starting Service %SVCNAME%
echo *************************************************************************
sc start %SVCNAME%
timeout 10 >NUL

:exit
cd %CMHOME%
echo *************************************************************************
echo * Job completed for %1 on %COMPUTERNAME%
echo *************************************************************************

if "%CMVarSetFile%" == "" goto :EOF
@echo CMERROR=%CMERROR%>%CMVarSetFile%
@echo CMERRORDESC=%CMERRORDESC%>>%CMVarSetFile%
