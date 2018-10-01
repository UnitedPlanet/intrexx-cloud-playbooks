@echo off
cls
echo --------------------------------------------------------
echo .
echo .           Installing 7-Zip - Please Wait.
echo .         (This window will close once installed)
echo .

REM Silent install 7-Zip for 64-bit
if defined ProgramFiles(x86) "%~dp07z1700-x64.msi" /q"
if defined ProgramFiles(x86) exit

REM Silent install 7-Zip for 32-bit
"%~dp07z1700.msi" /q"