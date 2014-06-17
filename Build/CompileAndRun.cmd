@echo off
:: 도중에 취소해도 Release폴더에만 찌꺼기가 남기 때문에 안전 ㅇㅅㅇ

:: tclkit.cmd에서 쓸 환경변수
set "onestop=true"

set "projdir=%~dp0.."
cd /D "%projdir%\Release"
echo starpack 생성 중...
call "%~dp0TclKit.cmd" "%projdir%\ApkzMain.vfs"
echo 아이콘 바꾸기 리팩 중...
call "%~dp0IcoPack.cmd" "ApkzMain.exe"
echo 정리하고 실행합니다.
move /Y "ApkzMain.exe" "ApkZipper%~1.exe"
start "" "ApkZipper%~1.exe"
copy /Y "ApkZipper%~1.exe" "C:\ApkZipper%~1.exe"