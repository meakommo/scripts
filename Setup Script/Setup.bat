@echo off
REM Running as admin? 
net session >nul
cls
if %ERRORLEVEL%==0 (
	goto start
) ELSE (
	@echo =========================
	@echo NOT RUNNING AS ADMIN. 
	@echo =========================
	@echo Please start this script as an admin user. 
	pause >nul
	exit
)

:start
cls
@echo ============================
@echo Setting up computer, please wait. 
@echo ============================
powershell Set-ExecutionPolicy -ExecutionPolicy Unrestricted
powershell -file "%~dp0powershel-Setup.ps1" "%~dp0" > output.txt
powershell Set-ExecutionPolicy -ExecutionPolicy restricted
pause >nul