cmake_minimum_required(VERSION 3.0)

project(CMakeRust)

#-------------------------------------------------------------
# Examples are only enabled if we are the top level project
#-------------------------------------------------------------
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

    enable_language(Rust)
    include(CMakeCargo)

    add_subdirectory(hello_world)
    add_subdirectory(crates)
endif()
