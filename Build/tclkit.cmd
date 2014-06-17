@echo off
prompt %$G 
set "initdir=%~dp0"
set "tclkit=%~dp0tclkit-cli-860.exe"
set "sdx=%~dp0sdx.kit"

:: tclkit자동화 배치스크립트 버전 (tclsh가 없어도 되는 버전)
:: 사용법, .tcl파일을 드래그해서 놓은 다음 (복수 지원) tcl console이 뜨면 전부 exit로 빠져나오자.
:: %CD%를 바꾸지 않고, 그 폴더에서 임시파일, 결과파일 모두를 만든다

:STARTSHIFT
taskkill /im tclkit.exe >nul 2>nul
SHIFT
if "%~0"=="" goto END
if exist "%~dpn0.vfs" goto WRAP
del "%~dpn0.exe" "%~dpn0.kit" >nul 2>nul
"%tclkit%" "%sdx%" qwrap "%~0"
"%tclkit%" "%sdx%" unwrap "%~dpn0.kit"
:WRAP
del "%~dpn0.exe" "%~dpn0.kit" >nul 2>nul
"%tclkit%" "%sdx%" wrap "%CD%\%~n0.exe" -vfs "%~dpn0.vfs" -runtime "%initdir%tclkit.exe"
del "%~dpn0.kit" >nul 2>nul
goto STARTSHIFT
:END
if not defined onestop pause