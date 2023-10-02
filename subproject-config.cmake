#[===[
        COPYRIGHT (c) 2019-2023 by Featuremine Corporation.

        This Source Code Form is subject to the terms of the Mozilla Public
        License, v. 2.0. If a copy of the MPL was not distributed with this
        file, You can obtain one at https://mozilla.org/MPL/2.0/.
]===]

function(git_clone)
    cmake_parse_arguments(
        ARG
        ""
        "GIT_REVISION;GIT_URL;DIR"
        ""
        ${ARGN}
    )
    string(MD5 HASH ${ARG_DIR})
    if (NOT EXISTS "${ARG_DIR}")
        find_package(Git REQUIRED)
        message(STATUS "Git cloning ${ARG_GIT_URL} ${ARG_GIT_REVISION}")
        execute_process(
            COMMAND
            "${GIT_EXECUTABLE}"
            "clone"
            "--recursive"
            "--depth"
            "1"
            "-b"
            "${ARG_GIT_REVISION}"
            "${ARG_GIT_URL}"
            "${ARG_DIR}"
            RESULT_VARIABLE ret
            ERROR_VARIABLE stderr
        )
        if(ret AND NOT ret EQUAL 0)
            message(FATAL_ERROR "git clone ${ARG_GIT_URL} failed: ${stderr}")
        endif()
        set(GITCLONE_${HASH}_REVISION_REQUESTED "${ARG_GIT_REVISION}" CACHE INTERNAL "Revision requested for git repo ${ARG_DIR}" FORCE)
    elseif(NOT GITCLONE_${HASH}_REVISION_REQUESTED STREQUAL ARG_GIT_REVISION)
        find_package(Git REQUIRED)
        execute_process(
            COMMAND
            "${GIT_EXECUTABLE}"
            "-C"
            "${ARG_DIR}"
            "fetch"
            "--depth"
            "1"
            "origin"
            "${ARG_GIT_REVISION}"
            RESULT_VARIABLE ret
            ERROR_VARIABLE stderr
        )
        if(ret AND NOT ret EQUAL 0)
            message(WARNING "git fetch ${ARG_GIT_URL} failed: ${stderr}")
        else()
            execute_process(
                COMMAND
                "${GIT_EXECUTABLE}"
                "-C"
                "${ARG_DIR}"
                "rev-parse"
                "FETCH_HEAD"
                RESULT_VARIABLE ret
                OUTPUT_VARIABLE stdout
                ERROR_VARIABLE stderr
                OUTPUT_STRIP_TRAILING_WHITESPACE
            )
            if(ret AND NOT ret EQUAL 0)
                message(WARNING "git rev-parse ${ARG_GIT_URL} failed: ${stderr}")
            else()
                execute_process(
                    COMMAND
                    "${GIT_EXECUTABLE}"
                    "-C"
                    "${ARG_DIR}"
                    "checkout"
                    "${stdout}"
                    RESULT_VARIABLE ret
                    OUTPUT_VARIABLE stdout
                    ERROR_VARIABLE stderr
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                )
                if(ret AND NOT ret EQUAL 0)
                    message(FATAL_ERROR "git rev-parse ${ARG_GIT_URL} failed: ${stderr}")
                else()
                    message("Git checkout ${ARG_GIT_URL} from ${GITCLONE_${HASH}_REVISION_REQUESTED} to ${ARG_GIT_REVISION}")
                    set(GITCLONE_${HASH}_REVISION_REQUESTED "${ARG_GIT_REVISION}" CACHE INTERNAL "Revision requested for git repo ${ARG_DIR}" FORCE)
                endif()
            endif()
        endif()
    endif()
endfunction()

function(add_subproject)
    cmake_parse_arguments(
        ARG
        ""
        "NAME;VERSION;VERSION_MIN;VERSION_MAX;GIT_REVISION;GIT_URL"
        "TARGETS;VARIABLES"
        ${ARGN}
    )
    set(ALREADY_EXISTS FALSE)
    foreach(TARGET_NAME IN LISTS ARG_TARGETS)
        if (TARGET ${TARGET_NAME})
            set(ALREADY_EXISTS TRUE)
        endif ()
    endforeach()
    foreach(VAR_NAME IN LISTS ARG_VARIABLES)
        if (DEFINED ${VAR_NAME})
            set(ALREADY_EXISTS TRUE)
        endif ()
    endforeach()
    if (NOT ALREADY_EXISTS)
        set(DEP_SRC_DIR "${CMAKE_BINARY_DIR}/dependencies/src/${ARG_NAME}")
        set(DEP_BIN_DIR "${CMAKE_BINARY_DIR}/dependencies/build/${ARG_NAME}")
        git_clone(
            GIT_REVISION ${ARG_GIT_REVISION}
            GIT_URL ${ARG_GIT_URL}
            DIR ${DEP_SRC_DIR}
        )

        cmake_policy(CMP0077 NEW)
        set(BUILD_SHARED_LIBS OFF)
        set(BUILD_TESTING OFF)
        set(BUILD_API_DOCS OFF)
        if (NOT ${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
            set(CMAKE_EXE_LINKER_FLAGS "-static-libstdc++ -static-libgcc")
        endif()
        add_subdirectory("${DEP_SRC_DIR}" "${DEP_BIN_DIR}" EXCLUDE_FROM_ALL)
        if (NOT ${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
            unset(CMAKE_EXE_LINKER_FLAGS)
        endif()
        unset(BUILD_API_DOCS)
        unset(BUILD_TESTING)
        unset(BUILD_SHARED_LIBS)

        foreach(VAR_NAME IN LISTS ARG_VARIABLES)
            get_directory_property(${VAR_NAME} DIRECTORY "${DEP_SRC_DIR}" DEFINITION ${VAR_NAME})
            set(${VAR_NAME} ${${VAR_NAME}} PARENT_SCOPE)
        endforeach()
    endif()

    set(original_proj_ver ${PROJECT_VERSION})
    set(PROJECT_VERSION "UNKNOWN")
    get_directory_property(${ARG_NAME}_VERSION DIRECTORY "${${ARG_NAME}_SOURCE_DIR}" DEFINITION PROJECT_VERSION)
    set(SUBPROJECT_${ARG_NAME}_VERSION "${${ARG_NAME}_VERSION}" CACHE INTERNAL "Subproject ${ARG_NAME} version" FORCE)
    set(PROJECT_VERSION ${original_proj_ver})

    if (ARG_VERSION OR ARG_VERSION_MIN OR ARG_VERSION_MAX)
        set(VERSION_CHECK_MODE "FATAL_ERROR")
        if (VERSIONCHECK_WARN)
            set(VERSION_CHECK_MODE "WARNING")
        endif ()
        if (ARG_VERSION AND NOT ${${ARG_NAME}_VERSION} VERSION_EQUAL "${ARG_VERSION}")
            message(${VERSION_CHECK_MODE} "${ARG_NAME} expected version ${ARG_VERSION}, got ${${ARG_NAME}_VERSION}")
        elseif (ARG_VERSION_MIN AND NOT ${${ARG_NAME}_VERSION} VERSION_GREATER_EQUAL "${ARG_VERSION_MIN}")
            message(${VERSION_CHECK_MODE} "${ARG_NAME} expected at least version ${ARG_VERSION_MIN}, got ${${ARG_NAME}_VERSION}")
        elseif (ARG_VERSION_MAX AND NOT ${${ARG_NAME}_VERSION} VERSION_LESS "${ARG_VERSION_MAX}")
            message(${VERSION_CHECK_MODE} "${ARG_NAME} expected version less than ${ARG_VERSION_MAX}, got ${${ARG_NAME}_VERSION}")
        endif ()
    endif ()
    message(STATUS "Using ${ARG_NAME} ${${ARG_NAME}_VERSION}")
endfunction()

function(add_make_subproject)
    cmake_parse_arguments(
        ARG
        ""
        "NAME;VERSION;VERSION_MIN;VERSION_MAX;GIT_REVISION;GIT_URL"
        ""
        ${ARGN}
    )
    set(ALREADY_EXISTS FALSE)
    foreach(TARGET_NAME IN LISTS ARG_TARGETS)
        if (TARGET ${TARGET_NAME})
            set(ALREADY_EXISTS TRUE)
        endif ()
    endforeach()
    if (NOT ALREADY_EXISTS)
        set(DEP_SRC_DIR "${CMAKE_BINARY_DIR}/dependencies/src/${ARG_NAME}")
        set(DEP_BIN_DIR "${CMAKE_BINARY_DIR}/dependencies/build/${ARG_NAME}")
        if (NOT EXISTS "${DEP_SRC_DIR}")
            message(STATUS "Downloading ${ARG_NAME} ${ARG_VERSION} ${ARG_GIT_REVISION}")
            git_clone(
                GIT_REVISION ${ARG_GIT_REVISION}
                GIT_URL ${ARG_GIT_URL}
                DIR ${DEP_SRC_DIR}
            )
        endif()
        set(LIB_PATH "${DEP_BIN_DIR}/lib/${ARG_NAME}.a")
        if (NOT EXISTS "${LIB_PATH}")
            execute_process(
                COMMAND
                "${CMAKE_COMMAND}" -E env
                "CC=${CMAKE_C_COMPILER}"
                "CXX=${CMAKE_CXX_COMPILER}"
                "PREFIX=${DEP_BIN_DIR}"
                "BINPATH=${DEP_BIN_DIR}/bin"
                "INCPATH=${DEP_BIN_DIR}/include"
                "LIBPATH=${DEP_BIN_DIR}/lib"
                "DATAPATH=${DEP_BIN_DIR}/data"
                "make"
                "-f"
                makefile
                "-j4"
                "install"
                RESULT_VARIABLE ret
                ERROR_VARIABLE stderr
                WORKING_DIRECTORY ${DEP_SRC_DIR}
            )
            if(ret AND NOT ret EQUAL 0)
                message(FATAL_ERROR "build ${ARG_GIT_URL} failed: ${stderr}")
            endif()
        endif()
        add_library(
            ${ARG_NAME}
            INTERFACE IMPORTED GLOBAL
        )
        target_include_directories(
            ${ARG_NAME}
            INTERFACE
            "${DEP_BIN_DIR}/include"
        )
        target_link_libraries(
            ${ARG_NAME}
            INTERFACE
            "${LIB_PATH}"
        )
    endif()
endfunction()
