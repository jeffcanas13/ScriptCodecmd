@echo off
@setlocal
@rem ******************************************************************
@rem ******************************************************************
@rem * CodeMove:
@rem *
@rem *   Arguments: %1 = ENVIRONMENT (e.g. STGPRE)
@rem *   Arguments: %2 = CodeMove#
@rem *   Arguments: %3 = Build#
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
@rem ******************************************************************
%~d0
SET CMNUM=%~2
SET BUILDNUM=%~3
SET CMHOME=%~dp0
CD "%CMHOME%"
if "%time:~0,1%"==" " goto AM
SET TIMESTAMP=%date:~10,4%%date:~4,2%%date:~7,2%%time:~0,2%%time:~3,2%%time:~6,2%%time:~9,2%
goto TSSET
:AM
SET TIMESTAMP=%date:~10,4%%date:~4,2%%date:~7,2%0%time:~1,1%%time:~3,2%%time:~6,2%%time:~9,2%
:TSSET

for /F "tokens=1-4 delims=:.," %%a in ("%TIME%") do (
   set TIMESTR=%%a.%%b.%%c.%%d
)
for /F "tokens=1-4 delims=/ " %%a in ("%DATE%") do (
   set DATESTR=%%d-%%b-%%c
)
@REM SET TIMESTAMP=%DATESTR%-%TIMESTR%

SET ENVCMD=SETENV_%~1.cmd 
if not exist %ENVCMD% goto syntax
call %ENVCMD%
@rem ******************************************************************
@rem * Sets Enviroment variables:
@rem *
@rem *     SVCNAME
@rem *     SVRROOT
@rem *     UPLDDIR
@rem *
@rem ******************************************************************
SET DOMOVE=false
SET WARFILES=false
SET CMERROR=false
SET CMERRORDESC=Success
@rem Setup a temporary file to pass error information between batch files.
SET CMVarSetFile=%TEMP%\CMVarSet_%TIMESTAMP%_%RANDOM%.bat
@echo CMERROR=%CMERROR%>%CMVarSetFile%
@echo CMERRORDESC=%CMERRORDESC%>>%CMVarSetFile%

if "%CMFTPServer%" == "" goto noftp
if "%CMNUM%" == "" goto noftp
@rem ******************************************************************
@rem * FTP Code Move. Calculate Move work directory
@rem *
@rem ******************************************************************
SET CMWORK=E:\CSCCodeMoves\MoveForm%CMNUM%-%1
SET CODEMOVESFX=
SET CODEMOVESFXSTG=
:workDirChk
if NOT exist "%CMWORK%%CODEMOVESFXSTG%" goto workDirDone
SET /A CODEMOVESFX=%CODEMOVESFX% + 1
SET CODEMOVESFXSTG=-%CODEMOVESFX%
goto workDirChk

:workDirDone
SET CMWORK=%CMWORK%%CODEMOVESFXSTG%
if NOT "%CODEMOVESFX%"=="" (
    SET CODEMOVESFX=-%CODEMOVESFX%
)
SET LGF=%CMWORK%\CodeMove%CODEMOVENUM%.log

MD "%CMWORK%"
if ERRORLEVEL 1 (
    SET CMERROR=true
    SET CMERRORDESC=Error creating Move Dir: %CMWORK%
    echo %CMERRORDESC%
    GOTO ftpalert
)
echo *************************************************************************>> "%LGF%"
echo * Created Code Move Directory: "%CMWORK%">> "%LGF%"
echo *************************************************************************>> "%LGF%"

SET CMFTPFolder=/%CMFTPHome%/%1/MoveForm%CMNUM%
echo *************************************************************************>> "%LGF%"
echo * FTPing Code Move Directory: %CMFTPFolder%>> "%LGF%"
echo *************************************************************************>> "%LGF%"
call powershell -File "%CMHome%FTPDir.ps1" -ftp ftp://%CMFTPServer% -folder %CMFTPFolder% -target %CMWORK%\ -user %CMUName% -pass %CMUPass% -errorFile %CMVarSetFile% | wtee -a "%LGF%
@rem Set error env variables returned from call 
for /f "delims=" %%i in (%CMVarSetFile%) do SET %%i
if %CMERROR%==true goto ftpalert

echo *************************************************************************>> "%LGF%"
echo * FTP Complete. Start Code Move at: %CMWORK%>> "%LGF%"
echo *************************************************************************>> "%LGF%"
SET UPLDDIR=%CMWORK%
@rem goto :EOF
for %%i in (%CMWORK%\*.war) do (
    SET DOMOVE=true
)

if %DOMOVE% == false (
    SET CMERROR=true
    SET CMERRORDESC=No war files found to move in Move Dir: %CMWORK%
    echo %CMERRORDESC%
    echo %CMERRORDESC%>> "%LGF%"
    GOTO ftpalert
)
    
call ApplyCodeUpdates.cmd %1 2>&1 | wtee -a "%LGF%"

:ftpalert
if %CMERROR% == false goto ftpalertok

call E:\CSC\Alerts\CodeMoveError\SendMail %TIMESTAMP% %~1 "%LGF%"
goto done

:ftpalertok
call E:\CSC\Alerts\CodeMoveComplete\SendMail %TIMESTAMP% %~1 "%LGF%"
goto done



:noftp
@echo ******************************************************************
@echo * Non-FTP Code Move
@echo ******************************************************************
for %%i in (%UPLDDIR%\*.war) do (
    SET DOMOVE=true
    SET WARFILES=true
)

SET MOVEDIRS=false
for /d %%i in (%UPLDDIR%\MoveForm*) do for %%x in (%%i\*.war) do (
    SET DOMOVE=true
    SET MOVEDIRS=true
)

@rem ******************************************************************
@rem ** If the service is stopped then perform code move process to 
@rem ** restart service regardless of whether there are war files
@rem ** to move.
@rem ******************************************************************
SET SVCSTATE=UNK
for /F "tokens=1,2,3,4" %%a in ('sc query "%SVCNAME%"') do if "%%a" == "STATE" SET SVCSTATE=%%d
if NOT "%SVCSTATE%" == "RUNNING" SET DOMOVE=true


if %DOMOVE% == true goto startmove
echo *************************************************************************
echo * No war files to move in: %UPLDDIR%
echo *************************************************************************
goto done

:startmove
if %MOVEDIRS% == true goto startmovedirs

:startmovewars
SET CMWORK=E:\CSCCodeMoves\AutomatedMoves\%TIMESTAMP%-%~1
MD "%CMWORK%"

SET LGF=%CMWORK%\CodeMove.log
call ApplyCodeUpdates.cmd %1 2>&1 | wtee -a "%LGF%"

if not exist E:\CSC\Alerts\CodeMoveComplete goto done
if %CMERROR% == false goto alertok
call E:\CSC\Alerts\CodeMoveError\SendMail %TIMESTAMP% %~1 "%LGF%"
goto done

:alertok
call E:\CSC\Alerts\CodeMoveComplete\SendMail %TIMESTAMP% %~1 "%LGF%"
goto done

:startmovedirs
for /d %%i in (%UPLDDIR%\MoveForm*) do (
    call CodeMoveDirs.cmd %1 %%i
)

if %WARFILES% == true goto startmovewars
goto done

:done
del /q "%CMVarSetFile%" 2>&1 >nul
goto exit

:syntax
call ENVLIST.cmd
echo *************************************************************************
echo * Syntax: CodeMove ENV
echo *         Where ENV = %ENVS%
echo *************************************************************************
SET CMERROR=true
goto exit

:exit
if %CMERROR% == true exit /B 8
@endlocal
