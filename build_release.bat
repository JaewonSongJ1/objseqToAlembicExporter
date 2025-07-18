@echo off
REM 
REM OBJ to Alembic Converter - Release Build Script
REM Static linking for standalone deployment
REM 
REM Author: Jaewon Song
REM Company: Dexter Studios
REM Position: R^&D Director
REM

echo =================================================
echo OBJ to Alembic Converter - Release Build
echo Author: Jaewon Song (Dexter Studios R^&D Director)
echo =================================================

REM Check for clean parameter
if "%1"=="clean" (
    echo [INFO] Cleaning previous build...
    if exist "build\release" rmdir /s /q "build\release"
    if exist "deploy" rmdir /s /q "deploy"
    echo [INFO] Clean completed. Run without 'clean' parameter to build.
    pause
    exit /b 0
)

echo [INFO] Building release version (static linking)
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
    echo 3. Run this script again: build_release.bat
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

REM Check if Alembic static is installed
echo [INFO] Checking Alembic static dependency...
"%VCPKG_ROOT%\vcpkg.exe" list | findstr "alembic.*x64-windows-static" >nul
if errorlevel 1 (
    echo [INFO] Alembic static not found. Installing...
    echo [WARNING] This may take 10-30 minutes for static build...
    "%VCPKG_ROOT%\vcpkg.exe" install alembic:x64-windows-static
    if errorlevel 1 (
        echo [ERROR] Failed to install Alembic static
        pause
        exit /b 1
    )
    echo [SUCCESS] Alembic static installed successfully
) else (
    echo [INFO] Alembic static already installed
)

REM Verify project structure
if not exist "src\main.cpp" (
    echo [ERROR] src\main.cpp not found
    echo Please ensure the project structure is correct:
    echo   src\main.cpp
    echo   CMakeLists.txt
    echo   build_release.bat
    echo.
    pause
    exit /b 1
)

REM Create build directory for release
echo [INFO] Setting up release build directory...
if not exist "build" mkdir build
if not exist "build\release" mkdir build\release
cd build\release

REM Configure with CMake for release (static linking)
echo [INFO] Configuring release build (static linking)...
echo [INFO] This will create a standalone executable...
cmake ..\.. ^
    -DCMAKE_TOOLCHAIN_FILE="%VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake" ^
    -DVCPKG_TARGET_TRIPLET=x64-windows-static ^
    -DCMAKE_BUILD_TYPE=Release ^
    -G "Visual Studio 17 2022" ^
    -A x64

if errorlevel 1 (
    echo [ERROR] CMake configuration failed
    echo.
    echo Troubleshooting:
    echo - Ensure Visual Studio 2022 is installed
    echo - Verify VCPKG_ROOT: %VCPKG_ROOT%
    echo - Try: vcpkg integrate install
    echo - Make sure alembic:x64-windows-static is installed
    echo - For clean build, run: build_release.bat clean
    echo.
    pause
    exit /b 1
)

REM Build the project in Release mode
echo [INFO] Building release version (this may take several minutes)...
cmake --build . --config Release

if errorlevel 1 (
    echo [ERROR] Build failed
    echo.
    echo Try cleaning and rebuilding: build_release.bat clean
    pause
    exit /b 1
)

cd ..\..

REM Clean and create deployment package
echo [INFO] Creating deployment package...
if exist "deploy" rmdir /s /q "deploy"
mkdir deploy

if exist "build\release\bin\Release\obj2abc.exe" (
    copy "build\release\bin\Release\obj2abc.exe" "deploy\"
    echo [SUCCESS] Copied executable to deploy folder
) else (
    echo [ERROR] Built executable not found
    pause
    exit /b 1
)

REM Create usage instructions
echo [INFO] Creating deployment instructions...
echo # OBJ to Alembic Converter - Deployment Package > deploy\README.txt
echo. >> deploy\README.txt
echo Author: Jaewon Song (Dexter Studios R^&D Director) >> deploy\README.txt
echo. >> deploy\README.txt
echo This is a standalone executable - no additional DLLs required. >> deploy\README.txt
echo. >> deploy\README.txt
echo Usage: >> deploy\README.txt
echo   obj2abc.exe -input "path\to\obj\sequence" -output "output.abc" [-fps 24] >> deploy\README.txt
echo. >> deploy\README.txt
echo Examples: >> deploy\README.txt
echo   obj2abc.exe -input ".\obj_sequence" -output "animation.abc" >> deploy\README.txt
echo   obj2abc.exe -input ".\obj_sequence" -output "animation.abc" -fps 30 >> deploy\README.txt

echo.
echo =================================================
echo [SUCCESS] Release build completed!
echo.
echo Standalone executable: deploy\obj2abc.exe
echo File size: ~30-50MB (includes all dependencies)
echo.
echo Ready for deployment:
echo - No DLLs required
echo - Can be copied to any Windows machine
echo - No installation needed
echo.
echo Distribution files:
echo   deploy\obj2abc.exe     - Main executable
echo   deploy\README.txt      - Usage instructions
echo.
echo For clean build: build_release.bat clean
echo =================================================
echo.

pause