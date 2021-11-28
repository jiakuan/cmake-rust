function(cargo_build)
    cmake_parse_arguments(CARGO "" "NAME" "SOURCES" ${ARGN})
    string(REPLACE "-" "_" LIB_NAME ${CARGO_NAME})

    set(CARGO_TARGET_DIR ${CMAKE_CURRENT_BINARY_DIR})

    if(WIN32)
        if(CMAKE_SIZEOF_VOID_P EQUAL 8)
            # Building with Clang on Windows in debug mode creates a mismatch
            # between the c runtime being dynamic release for the rust lib and
            # dynamic debug for cpp code. No clean solution have been found to
            # this issue. Using the -gnu target on Windows for the Rust lib and
            # building with mingw bypasses this.
            # https://github.com/trondhe/rusty_cmake
            # set(LIB_TARGET "x86_64-pc-windows-msvc")
            set(LIB_TARGET "x86_64-pc-windows-gnu")
        else()
            # set(LIB_TARGET "i686-pc-windows-msvc")
            set(LIB_TARGET "i686-pc-windows-gnu")
        endif()
    elseif(ANDROID)
        if(ANDROID_SYSROOT_ABI STREQUAL "x86")
            set(LIB_TARGET "i686-linux-android")
        elseif(ANDROID_SYSROOT_ABI STREQUAL "x86_64")
            set(LIB_TARGET "x86_64-linux-android")
        elseif(ANDROID_SYSROOT_ABI STREQUAL "arm")
            set(LIB_TARGET "arm-linux-androideabi")
        elseif(ANDROID_SYSROOT_ABI STREQUAL "arm64")
            set(LIB_TARGET "aarch64-linux-android")
        endif()
    elseif(IOS)
        set(LIB_TARGET "universal")
    elseif(CMAKE_SYSTEM_NAME STREQUAL Darwin)
        if(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "arm64")
            set(LIB_TARGET "aarch64-apple-darwin")
        else()
            set(LIB_TARGET "x86_64-apple-darwin")
        endif()
    else()
        if(CMAKE_SIZEOF_VOID_P EQUAL 8)
            set(LIB_TARGET "x86_64-unknown-linux-gnu")
        else()
            set(LIB_TARGET "i686-unknown-linux-gnu")
        endif()
    endif()

    if(NOT CMAKE_BUILD_TYPE)
        set(LIB_BUILD_TYPE "debug")
    elseif(${CMAKE_BUILD_TYPE} STREQUAL "Release")
        set(LIB_BUILD_TYPE "release")
    else()
        set(LIB_BUILD_TYPE "debug")
    endif()

    set(LIB_FILE "${CARGO_TARGET_DIR}/${LIB_TARGET}/${LIB_BUILD_TYPE}/${CMAKE_STATIC_LIBRARY_PREFIX}${LIB_NAME}${CMAKE_STATIC_LIBRARY_SUFFIX}")

    if(IOS)
        set(CARGO_ARGS "lipo")
    else()
        set(CARGO_ARGS "build")
        list(APPEND CARGO_ARGS "--target" ${LIB_TARGET})
    endif()

    if(${LIB_BUILD_TYPE} STREQUAL "release")
        list(APPEND CARGO_ARGS "--release")
    endif()

    #---------------------------------------------------------------------
    # The file(GLOB) and file(GLOB_RECURSE) commands are some of the
    # most misused parts of CMake. They should not be used to collect
    # a set of files to be used as sources, headers or any other set
    # of files that act as inputs to the build. One of the reasons
    # this should be avoided is that if files are added or removed,
    # CMake is not automatically re-run, so the build is unaware of
    # the change. (See: Professional CMake 7th edition - page 213)
    #
    # So, we should use 'SOURCES' arguments to get the source files
    #---------------------------------------------------------------------
    #file(GLOB_RECURSE LIB_SOURCES "*.rs")

    set(CARGO_ENV_COMMAND ${CMAKE_COMMAND} -E env "CARGO_TARGET_DIR=${CARGO_TARGET_DIR}")

    add_custom_command(
        OUTPUT ${LIB_FILE}
        COMMAND ${CARGO_ENV_COMMAND} ${CARGO_EXECUTABLE} ARGS ${CARGO_ARGS}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        # Use ${CARGO_SOURCES} instead of ${LIB_SOURCES} here
        DEPENDS ${CARGO_SOURCES}
        COMMENT "running cargo")
    add_custom_target(${CARGO_NAME}_target ALL DEPENDS ${LIB_FILE})
    add_library(${CARGO_NAME} STATIC IMPORTED GLOBAL)
    add_dependencies(${CARGO_NAME} ${CARGO_NAME}_target)
    set_target_properties(${CARGO_NAME} PROPERTIES IMPORTED_LOCATION ${LIB_FILE})

    # Configure include directory so the generated headers can be used
    message(STATUS "CARGO_TARGET_DIR: ${CARGO_TARGET_DIR}")
    set_target_properties(${CARGO_NAME} PROPERTIES NO_SYSTEM_FROM_IMPORTED true)
    target_include_directories(${CARGO_NAME} INTERFACE ${CARGO_TARGET_DIR})

    # Let CMake know how to test the Rust module
    add_test(NAME ${CARGO_NAME}_test
        COMMAND ${CARGO_ENV_COMMAND} ${CARGO_EXECUTABLE} test
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
endfunction()