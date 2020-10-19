@echo off
pushd "%~dp0"

PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& .\DailyMerge\DailyMerge.ps1";

popd
pause