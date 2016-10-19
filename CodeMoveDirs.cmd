@rem ******************************************************************
@rem ******************************************************************
@rem * CodeMoveDirs:
@rem *
@rem *   Arguments: %1 = ENVIRONMENT (e.g. STGPRE)
@rem *   Arguments: %2 = {UploadDirPath}\MoveForm999999 
@rem * *************************************************
@rem * This is a Called command file from CodeMove to process codemoves
@rem * of war files in a MoveForm999999 directory. 
@rem ******************************************************************
@rem ******************************************************************
SET MOVEDIR=%~n2
SET CODEMOVENUM=%MOVEDIR:~8%
if "%CODEMOVENUM%" == "" SET CODEMOVENUM=%TIMESTAMP:~0,8%

SET CMWORK=E:\CSCCodeMoves\MoveForm%CODEMOVENUM%-%1
if NOT EXIST "%CMWORK%" MD "%CMWORK%"

SET CODEMOVESFX=
SET LGSFX=
:logDupChk
if NOT exist "%CMWORK%\CodeMove%CODEMOVENUM%%LGSFX%.log" goto logDupChkDone
SET /A CODEMOVESFX=%CODEMOVESFX% + 1
SET LGSFX=-%CODEMOVESFX%
goto logDupChk

:logDupChkDone
SET LGF=%CMWORK%\CodeMove%CODEMOVENUM%%LGSFX%.log
call ApplyCodeUpdates.cmd %1 %MOVEDIR% 2>&1 | wtee -a "%LGF%"

@rem Set error env variables returned from batch call 
for /f "delims=" %%i in (%CMVarSetFile%) do SET %%i

if %CMERROR% == false goto alertok
call E:\CSC\Alerts\CodeMoveError\SendMail %CODEMOVENUM% %~1 "%LGF%"
goto exit

:alertok
call E:\CSC\Alerts\CodeMoveComplete\SendMail %CODEMOVENUM% %~1 "%LGF%"

:exit
if "%CMVarSetFile%" == "" goto :EOF
@echo CMERROR=%CMERROR%>%CMVarSetFile%
@echo CMERRORDESC=%CMERRORDESC%>>%CMVarSetFile%
