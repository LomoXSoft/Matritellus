@echo off
chcp 65001 >nul
echo === 1/2 Instalando Blender (winget) ===
winget install --id BlenderFoundation.Blender -e --source winget
set "BLENDER="
for /d %%D in ("%ProgramFiles%\Blender Foundation\Blender*") do if exist "%%D\blender.exe" set "BLENDER=%%D\blender.exe"
if not defined BLENDER (
  echo No encuentro blender.exe en "%ProgramFiles%\Blender Foundation"
  pause
  exit /b 1
)
echo === 2/2 Generando modelos con %BLENDER% ===
"%BLENDER%" -b --factory-startup -P "%~dp0critter_lowpoly.py" > "%~dp0blender_log.txt" 2>&1
type "%~dp0blender_log.txt"
echo.
echo === Terminado. Puedes cerrar esta ventana. ===
pause
