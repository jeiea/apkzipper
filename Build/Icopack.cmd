@echo off
:: based on: http://wiki.tcl.tk/10922
:: requires: .ico named after the executable
:: recoded by ũ��

set "upxbinary=%~dp0upx.exe"
set "reshacker=%~dp0reshacker.exe"
set "rcbinary=%~dp0rc.exe"

:STARTSHIFT
if not exist "%~dpn1.exe" (echo ���������� ������. ��ɾ �� �Է��ߴ��� Ȯ�����ּ���.& pause & goto :EOF)
if not exist "%~dpn1.ico" (echo ������������ ������. ������ �����̸��� �������� �̸��� ������ Ȯ�����ּ���.& pause & goto :EOF)

copy "%~dpn1.exe" "work1_%~n1.exe"
"%upxbinary%" -d "work1_%~n1.exe"
"%reshacker%" -delete "work1_%~n1.exe" , "work2_%~n1.exe" , icongroup,,
set "icopath=%~dpn1.ico"
echo TK ICON "%icopath:\=\\%" > "rc_%~n1.rc"
"%rcbinary%" "rc_%~n1.rc"
"%reshacker%" -add "work2_%~n1.exe" , "work3_%~n1.exe" , "rc_%~n1.res" , ,,
"%upxbinary%" --best "work3_%~n1.exe"
copy "work3_%~n1.exe" "%~dpn1.exe"
del "work1_%~n1.exe" "work2_%~n1.exe" "work3_%~n1.exe" "rc_%~n1.rc" "rc_%~n1.res"
shift
if not "%~1"=="" goto STARTSHIFT
if not defined onestop pause