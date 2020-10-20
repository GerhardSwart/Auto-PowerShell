powershell Set-ExecutionPolicy RemoteSigned 
powershell Set-ExecutionPolicy Unrestricted
cd %~dp0
%~d0

powershell -executionpolicy bypass -File ".\backend\Install-ChocoPrograms.ps1"
powershell -executionpolicy bypass -File ".\backend\Install-VSCodeExtentions.ps1"
powershell -executionpolicy bypass -File ".\backend\Install-WindowsSettings.ps1"
pause