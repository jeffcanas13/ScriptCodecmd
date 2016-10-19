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
@rem * Perform a code move for s SQL Database
@rem * This will call a command file to set the code move environment
@rem * variabless. The %1 argument is the name of the SETENV_%1.cmd
@rem * file to be called. 
@rem ******************************************************************
@rem ******************************************************************
%~d0
SET CMENV=%~1
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

SET ENVCMD=SETENV_%CMENV%.cmd 
if not exist %ENVCMD% goto syntax
call %ENVCMD%
@rem ******************************************************************
@rem * Sets Enviroment variables:
@rem *
@rem *     CMUType
@rem *     CMUName
@rem *     CMUPass
@rem *     CMServer
@rem *     UPLDDIR
@rem *
@rem ******************************************************************
SET DOMOVE=false
SET MOVEDIRS=false
@rem *** Setup a temporary file to pass error information between batch files.
SET CMVarSetFile=%TEMP%\CMVarSet_%TIMESTAMP%_%RANDOM%.bat


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

SETLOCAL
call "%~dp0SetEnvVarCred" %CMFTPUserType%
SET CMFTPFolder=/%CMFTPHome%/MoveForm%CMNUM%
echo *************************************************************************>> "%LGF%"
echo * FTPing Code Move Directory: %CMFTPFolder%>> "%LGF%"
echo *************************************************************************>> "%LGF%"
call powershell -File "%CMHome%FTPDir.ps1" -ftp ftp://%CMFTPServer% -folder %CMFTPFolder% -target %CMWORK%\ -user %CMUName% -pass %CMUPass% -errorFile %CMVarSetFile% | wtee -a "%LGF%
ENDLOCAL
@rem Set error env variables returned from call 
for /f "delims=" %%i in (%CMVarSetFile%) do SET %%i
if %CMERROR%==true goto ftpalert

echo *************************************************************************>> "%LGF%"
echo * FTP Complete. Start Code Move at: %CMWORK%>> "%LGF%"
echo *************************************************************************>> "%LGF%"
SET UPLDDIR=%CMWORK%
@rem goto :EOF
for %%i in (%CMWORK%\SQL.zip) do (
    SET DOMOVE=true
)

if %DOMOVE% == false (
    SET CMERROR=true
    SET CMERRORDESC=No SQL.zip files found to move in Move Dir: %CMWORK%
    echo %CMERRORDESC%
    echo %CMERRORDESC%>> "%LGF%"
    GOTO ftpalert
)
    
call CodeMoveSQLDirs.cmd %CMENV%
goto done 

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
for /d %%i in (%UPLDDIR%\MoveForm*) do for %%x in (%%i\SQL.zip) do (
    SET DOMOVE=true
    SET MOVEDIRS=true
)

if %DOMOVE% == true goto startmovedirs
echo *************************************************************************
echo * No SQL.zip files to move in: %UPLDDIR%
echo *************************************************************************
goto done

:startmovedirs
for /d %%i in (%UPLDDIR%\MoveForm*) do (
    SET CMERROR=false
    SET CMERRORDESC=Success
    @echo CMERROR=%CMERROR%>%CMVarSetFile%
    @echo CMERRORDESC=%CMERRORDESC%>>%CMVarSetFile%
    call CodeMoveSQLDirs.cmd %CMENV% %%i
)
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
