@echo off
REM ============================================================
REM Build OBJ Sequence to Alembic UI as a one-file EXE (Windows)
REM Project layout:
REM   <project_root>\ui\obj_seq_to_abc_ui.py
REM   <project_root>\deploy\obj2abc.exe
REM This script puts the UI EXE into <project_root>\deploy
REM ============================================================

setlocal

REM Change to repository root if this script is placed at root.
REM If you place this .bat elsewhere, adjust paths accordingly.
set PROJ=%~dp0
pushd "%PROJ%"

REM (Optional) activate your conda/venv here
REM call C:\tools\miniconda3\Scripts\activate.bat common_dev

REM Ensure packages
python -m pip install --upgrade pip
python -m pip install pyinstaller PyQt5

REM Clean old build
if exist build rmdir /s /q build
if exist dist rmdir /s /q dist

REM Build
pyinstaller ^
  ".\ui\obj_seq_to_abc_ui.py" ^
  --name "OBJSeqToAlembicUI" ^
  --onefile ^
  --windowed ^
  --noconfirm ^
  --clean ^
  --distpath ".\deploy"

echo.
echo ============================================================
echo  Done. Find EXE here:  .\deploy\OBJSeqToAlembicUI.exe
echo  Make sure obj2abc.exe is also in .\deploy\
echo ============================================================
echo.

popd
endlocal
