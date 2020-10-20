Cls

$packageXml = ''
choco list -lo -r | % { $_ -split '\|' | select -first 1 } | % { $packageXml += "`n`t<package id=""$_"" />" }
$contents = "<packages>$packageXml`n</packages>"
Set-Content -value $contents -path $PSScriptRoot\choco_packages.config

Write-Host "Choco packages list saved to ($PSScriptRoot\choco_packages.config)" -ForegroundColor Green
Write-Host "Done" -ForegroundColor Green

Exit