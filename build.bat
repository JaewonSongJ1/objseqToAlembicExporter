@echo off
REM 
REM OBJ Sequence to Alembic Cache Converter - Build Script
REM 
REM Author: Jaewon Song
REM Company: Dexter Studios
REM Position: R&D Director
REM

echo =================================================
echo OBJ to Alembic Converter Build Script
echo Author: Jaewon Song (Dexter Studios R^&D Director)
echo =================================================

set VCPKG_ROOT=C:\Users\jaewon.song\source\repos\vcpkg
set CMAKE_TOOLCHAIN_FILE=%VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake

echo Checking vcpkg installation...
if not exist "%VCPKG_ROOT%" (
    echo Error: vcpkg not found at %VCPKG_ROOT%
    pause
    exit /b 1
)

echo Checking Alembic installation...
if not exist "%VCPKG_ROOT%\packages\alembic_x64-windows" (
    echo Error: Alembic not found. Please install with: vcpkg install alembic:x64-windows
    pause
    exit /b 1
)

echo Checking project structure...
if not exist "src" (
    echo Creating src directory...
    mkdir src
)

if not exist "src\main.cpp" (
    echo Error: src\main.cpp not found. Please create this file from the provided artifact.
    pause
    exit /b 1
)

echo Creating build directory...
if not exist "build" mkdir build
cd build

echo Running CMake configure...
cmake .. ^
    -DCMAKE_TOOLCHAIN_FILE=%CMAKE_TOOLCHAIN_FILE% ^
    -DVCPKG_TARGET_TRIPLET=x64-windows ^
    -DCMAKE_BUILD_TYPE=Release ^
    -G "Visual Studio 17 2022" ^
    -A x64

if errorlevel 1 (
    echo CMake configure failed!
    pause
    exit /b 1
)

echo Building project...
cmake --build . --config Release

if errorlevel 1 (
    echo Build failed!
    pause
    exit /b 1
)

echo.
echo =================================================
echo Build completed successfully!
echo Executable location: build\bin\Release\obj2abc.exe
echo =================================================

pause