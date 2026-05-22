@echo off
setlocal
set "ROOT=%~dp0"
set "PATH=%ROOT%rocm\bin;%ROOT%bin;%PATH%"
echo HIP Library Path: %WINDIR%\SYSTEM32\amdhip64_7.dll
"%ROOT%bin\llama-server.exe" %*
