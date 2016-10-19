@SET SVCNAME=tcServer-prdpre
@SET SVRROOT=E:\Program Files\tcServer\instances\prdpre\webapps
@SET UPLDDIR=E:\CSCCodeMoves\Upload\PRDPRE
@SET CMFTPServer=iftp.fsg.amer.csc.com
@SET CMFTPHome=MemicJCM
@SET CMFTPUserType=CodeMoveUser
call "%~dp0SetEnvVarCred" %CMFTPUserType%
