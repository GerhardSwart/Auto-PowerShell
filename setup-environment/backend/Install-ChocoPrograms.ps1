#chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
Write-Host "Chocolatey Installed" -ForegroundColor Green
choco install .$PSScriptRoot\choco_packages.config -Y
Write-Host "Choco packages Install" -ForegroundColor Green

