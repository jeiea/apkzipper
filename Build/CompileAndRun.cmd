@echo off
:: ���߿� ����ص� Release�������� ��Ⱑ ���� ������ ���� ������

:: tclkit.cmd���� �� ȯ�溯��
set "onestop=true"

set "projdir=%~dp0.."
cd /D "%projdir%\Release"
echo starpack ���� ��...
call "%~dp0TclKit.cmd" "%projdir%\ApkzMain.vfs"
echo ������ �ٲٱ� ���� ��...
call "%~dp0IcoPack.cmd" "ApkzMain.exe"
echo �����ϰ� �����մϴ�.
move /Y "ApkzMain.exe" "ApkZipper%~1.exe"
start "" "ApkZipper%~1.exe"
copy /Y "ApkZipper%~1.exe" "C:\ApkZipper%~1.exe"