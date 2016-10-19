@echo off
@rem **********************************************************************
@rem * Syntax: DeployWar WarName UploadWarDir AppName WorkDir DeployDir
@rem **********************************************************************
@SETLOCAL
if "%~5" == "" goto invalidsyntax
SET WARNAME=%1
SET UPLOADDIR=%~2
SET WORKDIR=%~4
SET APPNAME=%3

SET APPDEPLOYDRIVE=%~d5
SET APPDEPLOYDIR=%~5\%APPNAME%
@if not exist "%APPDEPLOYDIR%" goto invaliddeploydir
cd /D "%APPDEPLOYDIR%"
if ERRORLEVEL 1 goto chdirerror

SET BACKDIR=backup
SET BACKSFX=
@if exist "%WORKDIR%\%BACKDIR%" SET /A BACKSFX=%BACKSFX% + 1
@if exist "%WORKDIR%\%BACKDIR%1" SET /A BACKSFX=%BACKSFX% + 1
@if exist "%WORKDIR%\%BACKDIR%2" SET /A BACKSFX=%BACKSFX% + 1
@if exist "%WORKDIR%\%BACKDIR%3" SET /A BACKSFX=%BACKSFX% + 1
@if exist "%WORKDIR%\%BACKDIR%4" SET /A BACKSFX=%BACKSFX% + 1
@if exist "%WORKDIR%\%BACKDIR%5" SET /A BACKSFX=%BACKSFX% + 1
@if exist "%WORKDIR%\%BACKDIR%6" SET /A BACKSFX=%BACKSFX% + 1
@if exist "%WORKDIR%\%BACKDIR%7" SET /A BACKSFX=%BACKSFX% + 1
@if exist "%WORKDIR%\%BACKDIR%8" SET /A BACKSFX=%BACKSFX% + 1
@if exist "%WORKDIR%\%BACKDIR%9" SET /A BACKSFX=%BACKSFX% + 1
SET WARBACK=%WORKDIR%\%BACKDIR%%BACKSFX%
if not exist "%WARBACK%" md "%WARBACK%"
@echo ************************************************************************
@echo * Backing up instance war directory:
@echo *      "%APPDEPLOYDIR%"
@echo *  to  "%WARBACK%\%WARNAME%"
@echo ************************************************************************

zip -q -r %WARBACK%\%WARNAME% *

@echo ************************************************************************
@echo * Removing war directory contents
@echo ************************************************************************
@rem  **************************************
@rem  * Check for locked files/directories
@rem  **************************************
SET LOCKED=false
for /d %%i in (*) do (
    ren "%%i" "%%i" 2> nul
    if ERRORLEVEL 1 (
        SET LOCKED=true
    )
)
if %LOCKED%==true goto lockedTarget
@rem  **************************************
@rem  * Perform delete
@rem  **************************************
del * /q
for /d %%i in (*) do rmdir /s/q %%i

if "%UPLOADDIR%" == "%WORKDIR%" goto noupload
@echo ************************************************************************
@echo * Deploying war file %WARNAME%
@echo *  to  "%APPDEPLOYDIR%"
@echo ************************************************************************
move /Y "%UPLOADDIR%\%WARNAME%" "%WORKDIR%"

:noupload
unzip -o -q %WORKDIR%\%WARNAME%
@echo ************************************************************************
@echo * Deploying war file %WARNAME% complete
@echo ************************************************************************
goto done 

:invaliddeploydir
SET CMERROR=true
SET CMERRORDESC=Error: Application deployment directory for %WARNAME% doesn't exist: "%APPDEPLOYDIR%"
@echo ************************************************************************
@echo * Error: Application deployment directory for %WARNAME% doesn't exist:
@echo *            "%APPDEPLOYDIR%"
@echo ************************************************************************
if "%UPLOADDIR%" == "%WORKDIR%" goto done
move "/Y %UPLOADDIR%\%WARNAME%" "%WORKDIR%"
goto done

:chdirerror
SET CMERROR=true
SET CMERRORDESC=Error: Couldn't change current directory to: "%APPDEPLOYDIR%"
@echo ************************************************************************
@echo * Error: Couldn't change current directory to:
@echo *            "%APPDEPLOYDIR%"
@echo ************************************************************************
goto done

:lockedTarget
SET CMERROR=true
SET CMERRORDESC=Files/directories are locked and cannot be deleted in deployment directory: "%APPDEPLOYDIR%"
@echo ************************************************************************
@echo * Error: Files/directories are locked and cannot be deleted in deployment directory:
@echo *            "%APPDEPLOYDIR%"
@echo ************************************************************************
goto done

:invalidsyntax
@echo ************************************************************************
@echo * Syntax: DeployWar WarName UploadWarDir AppName WorkDir DeployDir
@echo ************************************************************************

:done
if "%CMVarSetFile%"=="" goto done2
@echo CMERROR=%CMERROR%>%CMVarSetFile%
@echo CMERRORDESC=%CMERRORDESC%>>%CMVarSetFile%

:done2
@ENDLOCAL
