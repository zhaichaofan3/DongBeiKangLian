@echo off
setlocal
set "ASSET_GODOT=%~dp0..\..\..\tools\Godot-4.7.2\Godot_v4.7.2-stable_win64.exe"
if not exist "%ASSET_GODOT%" (
  echo Godot executable not found. Open viewer/project.godot in Godot 4.7.
  pause
  exit /b 1
)
start "" "%ASSET_GODOT%" --path "%~dp0viewer"
