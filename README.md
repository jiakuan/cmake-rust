# CMakeRust

This repository contains CMake files for integrating Rust code in C++ project.

It is forked from https://github.com/Devolutions/CMakeRust with fixes and improvements.

## Usage

Add the following to your Rust CMake module:

```
include(FetchContent)
FetchContent_Declare(cmake_rust
    GIT_REPOSITORY https://github.com/jiakuan/cmake-rust.git
    GIT_TAG 1.0.1)
FetchContent_MakeAvailable(cmake_rust)

list(APPEND CMAKE_MODULE_PATH ${cmake_rust_SOURCE_DIR}/cmake)

# Enable Rust language support (see: cmake-rust/cmake)
enable_language(Rust)
include(CMakeCargo)


# Use cargo_build to build Rust code as a CMake module
cargo_build(NAME my_rust_lib SOURCES src/lib.rs)
```
