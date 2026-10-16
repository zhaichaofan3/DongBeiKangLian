@echo off
if not defined BLENDER_EXE set "BLENDER_EXE=%~dp0tools\blender-4.5.14-windows-x64\blender.exe"
if not exist "%BLENDER_EXE%" (
    echo Blender is not available at the expected location.
    pause
    exit /b 1
)
start "" "%BLENDER_EXE%" %*
