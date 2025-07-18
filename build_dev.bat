@echo off
REM 
REM OBJ to Alembic Converter - Development Build Script
REM Fast build with dynamic linking for development/debugging
REM 
REM Author: Jaewon Song
REM Company: Dexter Studios
REM Position: R^&D Director
REM

echo =================================================
echo OBJ to Alembic Converter - Development Build
echo Author: Jaewon Song (Dexter Studios R^&D Director)
echo =================================================
echo [INFO] Building development version (dynamic linking)
echo.

REM Check if VCPKG_ROOT environment variable is set
if "%VCPKG_ROOT%"=="" (
    echo [ERROR] VCPKG_ROOT environment variable is not set.
    echo.
    echo Please install vcpkg and set the environment variable:
    echo.
    echo 1. Install vcpkg:
    echo    git clone https://github.com/Microsoft/vcpkg.git C:\vcpkg
    echo    cd C:\vcpkg
    echo    .\bootstrap-vcpkg.bat
    echo.
    echo 2. Set environment variable ^(choose one^):
    echo    - Current session: set VCPKG_ROOT=C:\vcpkg
    echo    - Permanent: Add VCPKG_ROOT=C:\vcpkg to system environment variables
    echo.
    echo 3. Run this script again: build_dev.bat
    echo.
    pause
    exit /b 1
)

echo [INFO] Using vcpkg from: %VCPKG_ROOT%

REM Verify vcpkg installation
if not exist "%VCPKG_ROOT%\vcpkg.exe" (
    echo [ERROR] vcpkg.exe not found at %VCPKG_ROOT%
    echo Please verify vcpkg is properly installed and bootstrapped.
    echo Run: %VCPKG_ROOT%\bootstrap-vcpkg.bat
    echo.
    pause
    exit /b 1
)

REM Check if Alembic is installed
echo [INFO] Checking Alembic dependency...
"%VCPKG_ROOT%\vcpkg.exe" list | findstr "alembic" >nul
if errorlevel 1 (
    echo [INFO] Alembic not found. Installing...
    "%VCPKG_ROOT%\vcpkg.exe" install alembic:x64-windows
    if errorlevel 1 (
        echo [ERROR] Failed to install Alembic
        pause
        exit /b 1
    )
    echo [SUCCESS] Alembic installed successfully
) else (
    echo [INFO] Alembic already installed
)

REM Verify project structure
if not exist "src\main.cpp" (
    echo [ERROR] src\main.cpp not found
    echo Please ensure the project structure is correct:
    echo   src\main.cpp
    echo   CMakeLists.txt
    echo   build_dev.bat
    echo.
    pause
    exit /b 1
)

REM Create build directory for development
echo [INFO] Setting up development build directory...
if not exist "build" mkdir build
if not exist "build\dev" mkdir build\dev
cd build\dev

REM Configure with CMake for development (dynamic linking)
echo [INFO] Configuring development build (dynamic linking)...
cmake ..\.. ^
    -DCMAKE_TOOLCHAIN_FILE="%VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake" ^
    -DVCPKG_TARGET_TRIPLET=x64-windows ^
    -DCMAKE_BUILD_TYPE=Debug ^
    -G "Visual Studio 17 2022" ^
    -A x64

if errorlevel 1 (
    echo [ERROR] CMake configuration failed
    echo.
    echo Troubleshooting:
    echo - Ensure Visual Studio 2022 is installed
    echo - Verify VCPKG_ROOT: %VCPKG_ROOT%
    echo - Try: vcpkg integrate install
    echo.
    pause
    exit /b 1
)

REM Build the project in Debug mode
echo [INFO] Building development version...
cmake --build . --config Debug

if errorlevel 1 (
    echo [ERROR] Build failed
    pause
    exit /b 1
)

cd ..\..

echo.
echo =================================================
echo [SUCCESS] Development build completed!
echo.
echo Executable: build\dev\bin\Debug\obj2abc.exe
echo Note: This version requires DLL files in the same directory
echo.
echo For deployment build, use: build_release.bat
echo =================================================
echo.

pause