@echo off

:: Set working dir
cd %~dp0 & cd ..

set PAUSE_ERRORS=1
call bat\PackTexture.bat
call bat\RunApp.bat

if errorlevel 1 goto error
goto end

:error
pause

:end
