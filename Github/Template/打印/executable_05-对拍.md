# 对拍 `对拍/`

> **用法**：把 `data.cpp`（数据生成器）、`ans.cpp`（标准 / 暴力解）、`test.cpp`（待测程序）放到同一目录，双击或命令行运行 `dp.bat`；可选参数为对拍轮数，默认 `100`。
> - 全部通过：退出码 `0`；出现**编译 / 运行失败**或**输出不一致**：退出码 `1`（可被上层脚本判断）。
> - 仅 Windows 的 `cmd`（`.bat`）可用；依赖 PATH 中的 `g++`（MinGW）。
> - 计时：`Measure-Command { dp.bat [n] | Out-Host }`。

---

## Windows 对拍脚本 `dp.bat`

- **流程**：编译三个程序 → 循环 `N` 轮：生成数据 → 分别运行 `ans` / `test` → 逐字节比较输出 → 不一致则打印 input / expected / got 并退出。
- **参数**：`dp.bat [轮数]`，缺省 `N=100`。
- **比较**：`fc /b` 为二进制精确比较，**行尾空格 / 多余空行 / 末尾换行**差异都会判错。
- **清理**：结束时删除 `data.exe` / `ans.exe` / `test.exe`。

```bat
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
```
