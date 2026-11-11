@echo off

rem Simple timer
rem Measure-Command { dp.bat [n] | Out-Host }

set N=100
if not "%~1"=="" set N=%~1

echo Compiling ...
g++ -O2 data.cpp -o data.exe  || goto :fail
g++ -O2 ans.cpp  -o ans.exe   || goto :fail
g++ -O2 test.cpp -o test.exe  || goto :fail
echo Compile OK
echo.

set /a cnt=0

:loop
set /a cnt+=1

data.exe > input.txt
if errorlevel 1 goto :fail

ans.exe  < input.txt > ans_out.txt
if errorlevel 1 goto :fail

test.exe < input.txt > test_out.txt
if errorlevel 1 goto :fail

fc /b ans_out.txt test_out.txt >nul
if errorlevel 1 goto :diff

echo  done %cnt%/%N%

if %cnt% lss %N% goto :loop

echo.
echo All %N% rounds passed.
set FAILED=0
goto :cleanup

:diff
echo.
echo *** MISMATCH at round %cnt% ***
echo ----- input -----
type input.txt
echo ----- expected -----
type ans_out.txt
echo ----- got -----
type test_out.txt
set FAILED=1
goto :cleanup

:fail
echo.
echo *** FAILED at round %cnt% (compile or run) ***
set FAILED=1

:cleanup
del data.exe ans.exe test.exe >nul 2>nul
exit /b %FAILED%
