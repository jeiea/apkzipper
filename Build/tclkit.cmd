@echo off
prompt %$G 
set "initdir=%~dp0"
set "tclkit=%~dp0tclkit-cli-860.exe"
set "sdx=%~dp0sdx.kit"

:: tclkit�ڵ�ȭ ��ġ��ũ��Ʈ ���� (tclsh�� ��� �Ǵ� ����)
:: ����, .tcl������ �巡���ؼ� ���� ���� (���� ����) tcl console�� �߸� ���� exit�� ����������.
:: %CD%�� �ٲ��� �ʰ�, �� �������� �ӽ�����, ������� ��θ� �����

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