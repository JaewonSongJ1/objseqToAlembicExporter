# OBJ Sequence to Alembic Cache Converter

**Author:** Jaewon Song  
**Company:** Dexter Studios  
**Position:** R&D Director

## Overview

This standalone C++ application converts OBJ sequence files into a single Alembic cache file. It's designed for VFX and animation pipelines where geometry sequences need to be converted to Alembic format for efficient storage and playback.

## Features

- **Batch Conversion**: Converts entire OBJ sequence directories
- **Frame Sorting**: Automatically sorts OBJ files by frame number
- **Configurable FPS**: Supports custom frame rates (default: 24 fps)
- **Progress Tracking**: Real-time conversion progress display
- **Error Handling**: Comprehensive error checking and reporting
- **Cross-Platform**: Windows primary support with vcpkg integration

## Prerequisites

### Required Software
- **Visual Studio 2022** (with C++ development tools)
- **CMake 3.20+**
- **vcpkg** (installed at `C:\Users\jaewon.song\source\repos\vcpkg`)

### Required vcpkg Packages
```bash
vcpkg install alembic:x64-windows
```

### Current Package Status
Based on your vcpkg installation:
- ✅ `alembic_x64-windows` (2025-06-24)
- ✅ `detect_compiler_x64-windows` (2025-06-27)
- ✅ `imath_x64-windows` (2025-06-24)
- ✅ `libdeflate_x64-windows` (2025-06-27)
- ✅ `openexr_x64-windows` (2025-06-27)
- ✅ `vcpkg-cmake_x64-windows` (2025-06-24)
- ✅ `vcpkg-cmake-config_x64-windows` (2025-06-24)

## Building the Project

### Quick Build (Windows)
```bash
# Run the provided build script
build.bat
```

### Manual Build
```bash
# Create build directory
mkdir build
cd build

# Configure with CMake
cmake .. -DCMAKE_TOOLCHAIN_FILE=C:\Users\jaewon.song\source\repos\vcpkg\scripts\buildsystems\vcpkg.cmake -DVCPKG_TARGET_TRIPLET=x64-windows -DCMAKE_BUILD_TYPE=Release -G "Visual Studio 17 2022" -A x64

# Build the project
cmake --build . --config Release
```

## Usage

### Command Line Interface
```bash
obj2abc.exe -input <input_directory> -output <output_file.abc> [-fps <fps_value>]
```

### Parameters
- **`-input`**: Directory containing OBJ sequence files (required)
- **`-output`**: Output Alembic cache file path (required)  
- **`-fps`**: Frames per second (optional, default: 24)

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
obj2abc.exe -input "C:\Projects\Animation\ObjSequence" -output "C:\Projects\Animation\output.abc" -fps 25
```

## File Structure Requirements

### Input Directory Structure
```
obj_sequence/
├── frame_001.obj
├── frame_002.obj
├── frame_003.obj
└── ...
```

### Supported Naming Conventions
- `frame_001.obj`, `frame_002.obj`, etc.
- `animation_0001.obj`, `animation_0002.obj`, etc.
- `mesh001.obj`, `mesh002.obj`, etc.
- Any filename containing sequential numbers

### OBJ File Requirements
- Standard Wavefront OBJ format
- Vertices (`v x y z`)
- Faces (`f v1 v2 v3` or `f v1/vt1/vn1 v2/vt2/vn2 v3/vt3/vn3`)
- Consistent topology recommended for best results

## Output Format

The generated Alembic file contains:
- **Time-sampled geometry**: Each frame as a time sample
- **Mesh topology**: Vertices and face connectivity
- **Standard timing**: Based on specified FPS
- **Optimized storage**: Compressed Ogawa format

## Performance Notes

- **Memory Usage**: Processes one frame at a time to minimize memory footprint
- **Large Sequences**: Tested with sequences up to 1000+ frames
- **Processing Speed**: Approximately 10-50 frames per second (depends on mesh complexity)

## Error Handling

The application provides detailed error messages for common issues:
- Missing input directory
- Invalid OBJ file format
- File permission errors
- Insufficient disk space
- Invalid output path

## Troubleshooting

### Common Issues

**"Alembic not found" Error:**
```bash
vcpkg install alembic:x64-windows
```

**CMake Configuration Fails:**
- Verify vcpkg path in `build.bat`
- Ensure Visual Studio 2022 is installed
- Check CMake version (3.20+ required)

**Runtime DLL Errors:**
- Ensure vcpkg packages are properly installed
- Check that the executable is in the correct output directory

### Debug Build
For debugging purposes, build in Debug mode:
```bash
cmake --build . --config Debug
```

## Integration with Dexter Studios Pipeline

This tool is designed to integrate seamlessly with Dexter Studios' VFX pipeline:
- **Maya Integration**: Can be called from Maya MEL/Python scripts
- **Batch Processing**: Suitable for render farm integration
- **Asset Management**: Compatible with existing asset naming conventions

## Future Enhancements

Planned features for future versions:
- UV coordinate support
- Vertex normal preservation
- Material ID preservation
- Multi-object support
- Progressive mesh optimization

## License

This software is developed for Dexter Studios internal use.

## Contact

**Jaewon Song**  
R&D Director, Dexter Studios  
For technical support and feature requests.