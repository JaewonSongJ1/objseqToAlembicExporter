#
# OBJ Sequence to Alembic Cache Converter
# 
# Author: Jaewon Song
# Company: Dexter Studios
# Position: R&D Director
#

cmake_minimum_required(VERSION 3.20)
project(ObjToAlembic VERSION 1.0.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Set output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# Compiler-specific options
if(MSVC)
    add_compile_options(/W4)
    add_compile_definitions(_CRT_SECURE_NO_WARNINGS)
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
else()
    add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# Find required packages
find_package(Alembic REQUIRED)

# Print found Alembic information
message(STATUS "Found Alembic: ${Alembic_FOUND}")
message(STATUS "Alembic Include Dirs: ${Alembic_INCLUDE_DIRS}")
message(STATUS "Alembic Libraries: ${Alembic_LIBRARIES}")

# Create executable
add_executable(ObjToAlembic
    src/main.cpp
)

# Set target properties
set_target_properties(ObjToAlembic PROPERTIES
    OUTPUT_NAME "obj2abc"
    DEBUG_POSTFIX "_d"
)

# Link libraries
target_link_libraries(ObjToAlembic
    PRIVATE
    Alembic::Alembic
)

# Include directories
target_include_directories(ObjToAlembic
    PRIVATE
    ${Alembic_INCLUDE_DIRS}
)

# Platform-specific settings
if(WIN32)
    # Windows specific settings
    set_target_properties(ObjToAlembic PROPERTIES
        WIN32_EXECUTABLE FALSE
    )
    
    # Copy DLLs to output directory for Windows
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(BUILD_TYPE "debug")
    else()
        set(BUILD_TYPE "release")
    endif()
    
    # Add post-build step to copy required DLLs
    add_custom_command(TARGET ObjToAlembic POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E echo "Build completed successfully"
    )
endif()

# Installation
install(TARGETS ObjToAlembic
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

# Print build information
message(STATUS "")
message(STATUS "=== Build Configuration ===")
message(STATUS "Project: ${PROJECT_NAME}")
message(STATUS "Version: ${PROJECT_VERSION}")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "Compiler: ${CMAKE_CXX_COMPILER_ID}")
message(STATUS "vcpkg Root: ${VCPKG_ROOT}")
message(STATUS "===========================")
message(STATUS "")