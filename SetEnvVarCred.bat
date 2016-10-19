:@echo off
SET CMUType=%1
for /F "tokens=1,2,3 usebackq" %%v IN (`reg QUERY HKEY_LOCAL_MACHINE\Software\CSC\ITO\Users -V %CMUType%`) DO if "%%v"=="%CMUType%" set CMUName=%%x
for /F "usebackq delims=" %%v IN (`powershell -File %~dp0\GetPass.ps1 -userType %CMUType%`) DO set CMUPass=%%v
