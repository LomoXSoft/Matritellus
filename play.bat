@echo off
rem Double-click to play Matritellus (Godot version).
set GODOT=C:\Users\luis_\Fable\tools\godot\Godot_v4.7.2-stable_win64.exe
if not exist "%GODOT%" (
  echo Godot not found at %GODOT%
  echo Edit play.bat and point GODOT at your Godot 4 executable.
  pause
  exit /b 1
)
start "" "%GODOT%" --path "%~dp0godot"
