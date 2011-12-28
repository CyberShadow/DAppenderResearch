@echo off
call dbuildr test2dll
call :test StringBuilder2Multi
call :test StringBuilder2MultiX
exit

:test
echo -------- %1 ---------
pmctest test2dll.dll test%1 200
echo.
