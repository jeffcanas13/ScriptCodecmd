@rem ******************************************************************
@rem ******************************************************************
@rem * CodeMoveSQLDirs:
@rem *
@rem *   Arguments: %1 = ENVIRONMENT (e.g. STGPRE)
@rem *   Arguments: %2 = {UploadDirPath}\MoveForm999999 (Blank for FTP moves)
@rem * *************************************************
@rem * This is a Called command file from CodeMove to process codemoves
@rem * of war files in a MoveForm999999 directory. 
@rem * If the second argument is blank then this is an FTP code move
@rem * and CMWORK is already set up.
@rem ******************************************************************
@rem ******************************************************************
SET UPLOADPATH=%~2
if "%UPLOADPATH%" == "" goto worksetupComplete

SET MOVEDIR=%~n2
SET CODEMOVENUM=%MOVEDIR:~8%
if "%CODEMOVENUM%" == "" SET CODEMOVENUM=%TIMESTAMP:~0,8%

SET CMWORK=E:\CSCCodeMoves\MoveForm%CODEMOVENUM%-%1
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

if NOT exist "%UPLOADPATH%\SQL.zip" (
    SET CMERROR=true
    SET CMERRORDESC=SQL Upload Move Dir missing SQL.zip: %UPLOADPATH%
    GOTO finish
)

echo *************************************************************************>> "%LGF%"
echo * Creating Code Move Directory: "%CMWORK%">> "%LGF%"
echo *************************************************************************>> "%LGF%"
MD "%CMWORK%"
if ERRORLEVEL 1 (
    SET CMERROR=true
    SET CMERRORDESC=Error creating Move Dir: %CMWORK%
    echo %CMERRORDESC%
    GOTO finish
)
echo *************************************************************************>> "%LGF%"
echo * Copying code move files to: "%CMWORK%">> "%LGF%"
echo *************************************************************************>> "%LGF%"
XCOPY /S/Y "%UPLOADPATH%\*" "%CMWORK%"
if ERRORLEVEL 1 (
    SET CMERROR=true
    SET CMERRORDESC=Error Copying Upload Move Dir: %UPLOADPATH% to Code Move Work: %CMWORK%
    GOTO finish
)
echo LGF: "%LGF%">> "%LGF%"


:worksetupComplete
call ApplySQLUpdates.cmd %1 2>&1 | wtee -a "%LGF%"

@rem Set error env variables returned from batch call 
for /f "delims=" %%i in (%CMVarSetFile%) do SET %%i
echo. >> "%LGF%"
echo CMERROR='%CMERROR%'>> "%LGF%"
echo CMERRORDESC='%CMERRORDESC%' >> "%LGF%"

if "%UPLOADPATH%" == "" goto finish
echo. >> "%LGF%"
echo ************************************************************************* >> "%LGF%"
echo * Cleanup Code Move Directory: "%UPLOADPATH%" >> "%LGF%"
echo ************************************************************************* >> "%LGF%"
@rem  **************************************
@rem  * Check for locked files/directories
@rem  **************************************
SET LOCKED=false
@ren %UPLOADPATH% %MOVEDIR%
if ERRORLEVEL 1 (
    SET LOCKED=true
)
if %LOCKED%==true goto lockedTarget

rd /s /q "%UPLOADPATH%"
goto finish

:lockedTarget
SET CMERROR=true
SET CMERRORDESC=SQL Upload Move Dir is locked and cannot be removed at Job completion: %UPLOADPATH%
echo %CMERRORDESC%  >> "%LGF%"
echo ************************************************************************* >> "%LGF%"
GOTO finish

:finish
if %CMERROR%==false goto alertok
call E:\CSC\Alerts\CodeMoveError\SendMail %CODEMOVENUM% %~1 "%LGF%"
goto exit

:alertok
call E:\CSC\Alerts\CodeMoveComplete\SendMail %CODEMOVENUM% %~1 "%LGF%"

:exit
if "%CMVarSetFile%" == "" goto :EOF
@echo CMERROR=%CMERROR%>%CMVarSetFile%
@echo CMERRORDESC=%CMERRORDESC%>>%CMVarSetFile%

