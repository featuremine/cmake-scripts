#[===[
        COPYRIGHT (c) 2019-2023 by Featuremine Corporation.

        This Source Code Form is subject to the terms of the Mozilla Public
        License, v. 2.0. If a copy of the MPL was not distributed with this
        file, You can obtain one at https://mozilla.org/MPL/2.0/.
]===]

macro(fm_config)
    if (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        SET(CMAKE_C_FLAGS_DEBUG "/Z7 /Od /GL")
        SET(CMAKE_CXX_FLAGS_DEBUG "/Z7 /Od /GL")
        # more about optimization options:
        # https://learn.microsoft.com/en-us/cpp/build/reference/o-options-optimize-code?view=msvc-170
        SET(CMAKE_C_FLAGS_RELEASE "/O2 /Ot /Ob3 -DNDEBUG /GL")
        SET(CMAKE_CXX_FLAGS_RELEASE "/O2 /Ot /Ob3 -DNDEBUG /GL")
        # -w
        # /W0
        # -Qunused-arguments
        # /wd4100 unused formal parameter
        # /wd4189 unused local variable
        # -Wpedantic
        # /W4
        # -Wno-c++20-designator
        # /wd4221
        # -Wno-extra-semi
        # -
        # -Wno-c99-extensions
        # /wd4204
        # /wd4221
        # -Wno-vla-extension
        # /wd4200-4209
        # -Wno-flexible-array-extensions
        # /wd4200
        # /wd4201
        # -Wno-gnu-statement-expression
        # does not support GCC/Clang ({ ... }) statement expression extension
        # -Wno-gnu-zero-variadic-macro-arguments
        # /Zc:preprocessor to enable them
        # Wno-null-dereference
        # -
        # -Wduplicate-decl-specifier
        # -
        # -Waddress
        # I can't find it in GCC or Clang flags either
        # -Warray-bounds
        # /w14789
        # -Wchar-subscripts
        # generally handled via Level 4 (/W4) or /Wall warnings
        # -Winit-self
        # MSVC typically handles this scenario by treating the variable 
        # as uninitialized and reporting a level 1 C4700 warning
        # -Wreturn-type
        # /w14789
        # -Wsequence-point
        # /w14138 
        # /w14701-4702
        # -Wstrict-aliasing
        # Use high optimization levels (/O2 or /Ox) 
        # along with Link Time Code Generation (/GL or /LTCG)
        # -Wunused-function
        # /w14505
        # unknown pragma 'clang'
        # /wd4068
        # -Wunused-label
        # /w34102
        # -Wunused-variable
        # /w14101
        # -Winvalid-pch
        # MSVC treats PCH mismatches (different compiler flags, file paths, or versions) 
        # as Fatal Error C1083 (cannot open file) or C1853 (PCH header file is invalid)
        # -Wall
        # /W4
        string(APPEND CMAKE_C_FLAGS " /Zc:preprocessor /W0 /W4 /wd4068 /wd4100 /w14789 /w14138 /w14701 /w14702 /w14505 /w34102 /w14101")
        string(APPEND CMAKE_CXX_FLAGS " /Zc:preprocessor /W4 /wd4068 /wd4221 /wd4200 /wd4201 /wd4202 /wd4203 /wd4204 /wd4205 /wd4206 /wd4206 /wd4207 /wd4208 /wd4209 /w14789 /w14138 /w14701 /w14702 /w14505 /w34102 /w14101")
        set(CMAKE_CXX_STANDARD 20)
    else()
        SET(CMAKE_C_FLAGS_DEBUG "-g -O0")
        SET(CMAKE_CXX_FLAGS_DEBUG "-g -O0")
        SET(CMAKE_C_FLAGS_RELEASE "-O3 -DNDEBUG")
        SET(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")

        if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
            string(APPEND CMAKE_CXX_FLAGS " -fconcepts -fpermissive")
            string(APPEND CMAKE_EXE_LINKER_FLAGS " -static-libgcc -static-libstdc++")
            string(APPEND CMAKE_SHARED_LINKER_FLAGS " -static-libgcc -static-libstdc++")
            set(CMAKE_CXX_STANDARD 20)
        elseif (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
            string(APPEND CMAKE_C_FLAGS " -w -Qunused-arguments -Wpedantic")
            string(APPEND CMAKE_CXX_FLAGS " -Wpedantic -Wno-c++20-designator -Wno-extra-semi -Wno-c99-extensions -Wno-vla-extension -Wno-flexible-array-extensions -Wno-gnu-statement-expression -Wno-gnu-zero-variadic-macro-arguments -Wno-null-dereference")
            set(CMAKE_CXX_STANDARD 20)
        else()
            set(CMAKE_CXX_STANDARD 20)
        endif ()
        string(APPEND CMAKE_C_FLAGS " -Wduplicate-decl-specifier -Waddress -Warray-bounds -Wchar-subscripts -Winit-self -Wreturn-type -Wsequence-point -Wstrict-aliasing -Wunused-function -Wunused-label -Wunused-variable -Winvalid-pch -Wall")
        string(APPEND CMAKE_CXX_FLAGS " -Waddress -Warray-bounds -Wchar-subscripts -Winit-self -Wreturn-type -Wsequence-point -Wstrict-aliasing -Wunused-function -Wunused-label -Wunused-variable -Winvalid-pch -Wnon-virtual-dtor -Wall")
    endif()
    if (NOT ${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
        string(APPEND CMAKE_SHARED_LINKER_FLAGS " -Wl,--exclude-libs,ALL")
    endif()

    add_definitions(-D_FILE_OFFSET_BITS=64)

    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
    set(CMAKE_CXX_VISIBILITY_PRESET hidden)
    set(CMAKE_C_VISIBILITY_PRESET hidden)
    set(CMAKE_VISIBILITY_INLINES_HIDDEN ON)
endmacro()
