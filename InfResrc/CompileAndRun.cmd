@echo off
cd /D "%~dp0..\"
set onestop=pause needless
"%~dp0TclKit.lnk" "%~dp0..\ApkzMain.vfs"
move "%~dp0..\ApkzMain.exe" "%~dp0ApkzMain.exe"
"%~dp0IcoPack.lnk" "%~dp0ApkzMain.exe"
move "%~dp0ApkzMain.exe" "%~dp0..\Release\ApkZipper%~1.exe"
start "" "%~dp0..\Release\ApkZipper%~1.exe"
copy /Y "%~dp0..\Release\ApkZipper%~1.exe" "C:\ApkZipper%~1.exe"