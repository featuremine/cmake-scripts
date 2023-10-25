#[===[
        COPYRIGHT (c) 2019-2023 by Featuremine Corporation.

        This Source Code Form is subject to the terms of the Mozilla Public
        License, v. 2.0. If a copy of the MPL was not distributed with this
        file, You can obtain one at https://mozilla.org/MPL/2.0/.
]===]

macro(fm_config)
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        string(APPEND CMAKE_CXX_FLAGS " -fconcepts -fpermissive")
        string(APPEND CMAKE_EXE_LINKER_FLAGS " -static-libgcc -static-libstdc++")
        string(APPEND CMAKE_SHARED_LINKER_FLAGS " -static-libgcc -static-libstdc++")
        set(CMAKE_CXX_STANDARD 17)
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
        string(APPEND CMAKE_C_FLAGS " -w -Qunused-arguments -Wpedantic")
        string(APPEND CMAKE_CXX_FLAGS " -Wpedantic -Wno-c++20-designator -Wno-extra-semi -Wno-c99-extensions -Wno-vla-extension -Wno-flexible-array-extensions -Wno-gnu-statement-expression -Wno-gnu-zero-variadic-macro-arguments -Wno-null-dereference")
        set(CMAKE_CXX_STANDARD 20)
        if (CMAKE_BUILD_TYPE STREQUAL "Debug")
            string(APPEND CMAKE_C_FLAGS " -g -O0")
            string(APPEND CMAKE_CXX_FLAGS " -g -O0")
        endif()
    else()
        set(CMAKE_CXX_STANDARD 17)
    endif ()
    if (NOT ${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
        string(APPEND CMAKE_SHARED_LINKER_FLAGS " -Wl,--exclude-libs,ALL")
    endif()

    string(APPEND CMAKE_C_FLAGS " -Wduplicate-decl-specifier -Waddress -Warray-bounds -Wchar-subscripts -Winit-self -Wreturn-type -Wsequence-point -Wstrict-aliasing -Wunused-function -Wunused-label -Wunused-variable -Winvalid-pch -Wall")
    string(APPEND CMAKE_CXX_FLAGS " -Waddress -Warray-bounds -Wchar-subscripts -Winit-self -Wreturn-type -Wsequence-point -Wstrict-aliasing -Wunused-function -Wunused-label -Wunused-variable -Winvalid-pch -Wnon-virtual-dtor -Wall")
    add_definitions(-D_FILE_OFFSET_BITS=64)

    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
    set(CMAKE_CXX_VISIBILITY_PRESET hidden)
    set(CMAKE_C_VISIBILITY_PRESET hidden)
    set(CMAKE_VISIBILITY_INLINES_HIDDEN ON)
endmacro()
