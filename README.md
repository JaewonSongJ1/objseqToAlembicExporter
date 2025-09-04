# OBJ Sequence to Alembic Cache Converter

**Author:** Jaewon Song  
**Company:** Dexter Studios  
**Position:** R&D Director

## Overview

OBJ sequence files을 하나의 Alembic cache file로 변환하는 C++ standalone 프로그램입니다.

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Platform](https://img.shields.io/badge/platform-Windows-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- 🔄 **Batch Conversion**: OBJ sequence 전체 폴더 변환
- 📐 **Frame Sorting**: 파일명 기반 자동 프레임 정렬  
- ⚡ **Configurable FPS**: 사용자 정의 프레임레이트 (기본: 24fps)
- ✅ **Normal Fix**: Maya 호환 normal orientation 자동 수정
- 📊 **Progress Tracking**: 실시간 변환 진행률 표시

## Prerequisites

### 1. Required Software
- **Windows 10/11** (64-bit)
- **Visual Studio 2022** with C++ development tools
- **CMake 3.20+** 
- **Git** (for cloning)

### 2. vcpkg Installation

vcpkg가 설치되어 있지 않다면 다음 단계를 따라 설치하세요:

```bash
# 1. Clone vcpkg
git clone https://github.com/Microsoft/vcpkg.git C:\vcpkg
cd C:\vcpkg

# 2. Run bootstrap script
.\bootstrap-vcpkg.bat

# 3. Integrate with Visual Studio (optional but recommended)
.\vcpkg integrate install
```

### 3. Environment Variable Setup

**Important**: `VCPKG_ROOT` 환경변수를 설정해야 합니다.

**방법 1: 시스템 환경변수 (권장)**
1. `Windows + R` → `sysdm.cpl` → Enter
2. "고급" 탭 → "환경 변수" 클릭
3. "시스템 변수"에서 "새로 만들기" 클릭
4. 변수 이름: `VCPKG_ROOT`
5. 변수 값: `C:\vcpkg` (또는 설치한 경로)

**방법 2: 임시 설정 (현재 세션만)**
```bash
set VCPKG_ROOT=C:\vcpkg
```

## Installation

### For Development
```bash
# 1. Clone repository
git clone https://github.com/JaewonSongJ1/objseqToAlembicExporter.git
cd objseqToAlembicExporter

# 2. Development build (fast)
build_dev.bat
```

### For Company Deployment
```bash
# 1. Clone repository (on build machine)
git clone https://github.com/JaewonSongJ1/objseqToAlembicExporter.git
cd objseqToAlembicExporter

# 2. Release build (standalone)
build_release.bat

# 3. Distribute the deploy/ folder to all workstations
# No additional setup required on target machines
```

## Usage

### Command Line Interface

```bash
obj2abc.exe -input <obj_folder> -output <output.abc> [-fps <fps>]
```

### Parameters
- **`-input`**: OBJ sequence 폴더 경로 (필수)
- **`-output`**: 출력 Alembic 파일 경로 (필수)
- **`-fps`**: 프레임레이트 (선택, 기본값: 24)

### Examples

**Basic Usage:**
```bash
obj2abc.exe -input "./obj_sequence" -output "./animation.abc"
```

**Custom FPS:**
```bash
obj2abc.exe -input "./obj_sequence" -output "./animation.abc" -fps 30
```

**Full Paths:**
```bash
obj2abc.exe -input "D:\Projects\Animation\ObjSequence" -output "D:\Output\animation.abc" -fps 25
```

## Input Requirements

### Supported File Structure
```
obj_sequence/
├── frame_001.obj
├── frame_002.obj
├── frame_003.obj
└── ...
```

### Supported Naming Patterns
- `frame_001.obj`, `frame_002.obj`
- `animation_0001.obj`, `animation_0002.obj` 
- `mesh001.obj`, `mesh002.obj`
- Any filename with sequential numbers

### OBJ File Format
- Standard Wavefront OBJ format
- Vertices: `v x y z`
- Faces: `f v1 v2 v3` or `f v1/vt1/vn1 v2/vt2/vn2 v3/vt3/vn3`

## Output

생성된 Alembic 파일:
- ✅ Time-sampled geometry with proper frame timing
- ✅ Maya 호환 normal orientation (자동 수정됨)
- ✅ Compressed Ogawa format for optimal file size
- ✅ Industry-standard Alembic format

## Troubleshooting

### Common Issues

**❌ "VCPKG_ROOT environment variable is not set"**
```bash
# Solution: Set environment variable
set VCPKG_ROOT=C:\vcpkg
```

**❌ "Alembic not found"**
```bash
# Solution: Install Alembic
%VCPKG_ROOT%\vcpkg install alembic:x64-windows
```

**❌ "Visual Studio not found"**
- Install Visual Studio 2022 with C++ development tools
- Or use Visual Studio Build Tools 2022

**❌ "CMake not found"**
- Install CMake from https://cmake.org/download/
- Make sure CMake is in your PATH

### Debug Build
```bash
# For debugging purposes
cmake --build build --config Debug
```

## Performance

- **Memory**: ~50MB per 1000 frames
- **Speed**: ~10-50 frames/second (mesh complexity dependent)
- **File Size**: ~70% smaller than uncompressed formats

## Integration

### Maya Integration
```python
# Example Maya Python script
import subprocess
subprocess.call([
    "obj2abc.exe", 
    "-input", "C:/temp/obj_sequence",
    "-output", "C:/temp/animation.abc", 
    "-fps", "24"
])
```

### Batch Processing
```bash
# Process multiple sequences
for /D %%d in (D:\sequences\*) do (
    obj2abc.exe -input "%%d" -output "D:\output\%%~nd.abc"
)
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

### v1.0.0 (Latest)
- ✅ Initial release
- ✅ OBJ sequence to Alembic conversion
- ✅ Configurable FPS support
- ✅ Fixed normal orientation for Maya compatibility
- ✅ Automatic dependency installation

## Contact

**Jaewon Song**  
R&D Director, Dexter Studios  
- GitHub: [@JaewonSongJ1](https://github.com/JaewonSongJ1)
- Repository: [objseqToAlembicExporter](https://github.com/JaewonSongJ1/objseqToAlembicExporter)

---
*Built with ❤️ for the VFX community*

---

## GUI (PyQt5) — OBJ Sequence to Alembic Cache Exporter

본 저장소에는 C++ CLI(`obj2abc.exe`)와 함께 간단한 GUI가 포함됩니다. GUI는 **OBJ to Alembic** 기능만을 제공하며, 다음 경로와 구조를 가정합니다.

```text
<project_root>/
├─ ui/
│  └─ obj_seq_to_abc_ui.py        # GUI 소스 (PyQt5)
├─ deploy/
│  ├─ obj2abc.exe                 # C++ 변환기 (필수)
│  └─ OBJSeqToAlembicUI.exe       # (선택) 빌드된 GUI 실행파일
└─ example/
   └─ obj_sequence/               # 샘플 OBJ 시퀀스 (~120 files)
```

### 1) GUI 실행 (소스)
```bat
cd <project_root>
pip install PyQt5
python .\ui\obj_seq_to_abc_ui.py
```

- 실행 시 GUI는 자동으로 `<project_root>\deploy\obj2abc.exe` 를 탐색합니다. 없으면 오류를 표시합니다.
- 변환 명령은 CLI와 동일하게 동작합니다 (입력/출력/FPS 설정 후 **Convert to Alembic**).

### 2) GUI 실행파일(one-file) 빌드 (Windows)
PyInstaller 기반 단일 실행파일(one-file) 빌드 스크립트를 제공합니다.

```bat
cd <project_root>
build_win_pyinstaller.bat
```

- 결과물: `deploy/OBJSeqToAlembicUI.exe`
- 같은 폴더 `deploy/` 안에 **obj2abc.exe** 가 있어야 GUI가 동작합니다.

### 3) Quick Start (Example 데이터로 테스트)
예제 OBJ 시퀀스가 `<project_root>\example\obj_sequence` 에 있다고 가정합니다.

- **Input Folder**: `<project_root>\example\obj_sequence`
- **Output File**: `<project_root>\deploy\example_export.abc`
- **FPS**: 24 (또는 필요 시 변경)
- **Convert to Alembic** 클릭 → 변환 로그/진행 상태가 하단에 표시됩니다.

### 4) 명령행(CLI)와의 대응
GUI는 내부적으로 다음과 같은 CLI를 호출합니다 (예시):  
```bat
obj2abc.exe -input "<obj_folder>" -output "<output.abc>" -fps 24
```

### 5) 문제 해결
- **UI가 바로 종료됨**: `deploy/obj2abc.exe` 존재/실행 권한 확인, `Output File` 경로 유효성 확인
- **OBJ가 감지되지 않음**: 입력 폴더 내 `.obj` 확장자 확인, 파일명 순서 및 개수 확인
- **FPS 불일치 재생**: DCC(Maya 등) 씬의 FPS를 export에 사용한 FPS와 동일하게 설정

> CLI 사용법과 파라미터 상세는 아래 **Usage** 섹션을 참고하세요.
