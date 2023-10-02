#[===[
        COPYRIGHT (c) 2019-2023 by Featuremine Corporation.

        This Source Code Form is subject to the terms of the Mozilla Public
        License, v. 2.0. If a copy of the MPL was not distributed with this
        file, You can obtain one at https://mozilla.org/MPL/2.0/.
]===]

set(MODULE_PATH ${CMAKE_CURRENT_LIST_DIR})

function(python_package)
    cmake_parse_arguments(
        ARG
        ""
        "NAME;SHORT_DESCRIPTION;LONG_DESCRIPTION;SRC_DIR;BUILD_DIR;TESTS_PACKAGE"
        "PACKAGES;SCRIPTS;INSTALL_REQUIRES"
        ${ARGN}
    )
    find_program(PYTHON3_BIN "python3" REQUIRED)
    if(CMAKE_BUILD_TYPE MATCHES DEBUG)
        set(DEBUG_FLAG "--debug")
    endif()
    set(WHEEL_${ARG_NAME}_BUILD_DIR "${ARG_BUILD_DIR}/build" CACHE INTERNAL "Wheel path for ${ARG_NAME}" FORCE)
    set(TESTS_PACKAGE "${ARG_TESTS_PACKAGE}")
    configure_file(
        "${MODULE_PATH}/python/test-any-python"
        "${ARG_BUILD_DIR}/test-${ARG_NAME}-python"
        ESCAPE_QUOTES @ONLY
    )
    list(APPEND ARG_SCRIPTS "${ARG_BUILD_DIR}/test-${ARG_NAME}-python")
    string(JOIN ":" PACKAGES ${ARG_PACKAGES})
    string(JOIN ":" SCRIPTS ${ARG_SCRIPTS})
    string(JOIN ":" INSTALL_REQUIRES ${ARG_INSTALL_REQUIRES})
    set(
        SET_ENV_VAR
        ${CMAKE_COMMAND} -E env
        "PACKAGE_NAME=${ARG_NAME}"
        "PACKAGE_VERSION=${PROJECT_VERSION}"
        "PACKAGE_DESCRIPTION=${ARG_SHORT_DESCRIPTION}"
        "PACKAGE_LONG_DESCRIPTION=${ARG_LONG_DESCRIPTION}"
        "PACKAGES=${PACKAGES}"
        "SCRIPTS=${SCRIPTS}"
        "INSTALL_REQUIRES=${INSTALL_REQUIRES}"
    )

    set(TARGET "${CMAKE_BINARY_DIR}/output/${ARG_NAME}-${PROJECT_VERSION}-py3-none-any.whl")
    cmake_path(RELATIVE_PATH TARGET BASE_DIRECTORY "${CMAKE_BINARY_DIR}")
    add_custom_command(
        OUTPUT
        "${CMAKE_BINARY_DIR}/output/${ARG_NAME}-${PROJECT_VERSION}-py3-none-any.whl"

        DEPENDS
        "${ARG_BUILD_DIR}/test-${ARG_NAME}-python"
        "${MODULE_PATH}/python/setup.py"
        "${MODULE_PATH}/python/depfile.py"

        DEPFILE
        "${CMAKE_CURRENT_BINARY_DIR}/python-${ARG_NAME}-whl.d"

        COMMAND
        ${SET_ENV_VAR}
        "${PYTHON3_BIN}" "${MODULE_PATH}/python/setup.py"

        "build"
        "--build-base=${ARG_BUILD_DIR}/whl/build"
        "--build-lib=${ARG_BUILD_DIR}/whl/build/lib"
        "--build-scripts=${ARG_BUILD_DIR}/whl/build/scripts"
        ${DEBUG_FLAG}

        "egg_info"
        "--egg-base" "${ARG_BUILD_DIR}/whl"

        "bdist_wheel"
        "--bdist-dir=${ARG_BUILD_DIR}/whl/bdist"
        "--dist-dir=${CMAKE_BINARY_DIR}/output"

        COMMAND
        "${PYTHON3_BIN}" "${MODULE_PATH}/python/depfile.py"

        "--target" "${TARGET}"
        "--sources" "${ARG_BUILD_DIR}/whl/${ARG_NAME}.egg-info/SOURCES.txt"
        "--output" "${CMAKE_CURRENT_BINARY_DIR}/python-${ARG_NAME}-whl.d"

        WORKING_DIRECTORY "${ARG_SRC_DIR}"
    )
    add_custom_target(
        ${ARG_NAME}-whl ALL
        DEPENDS "${CMAKE_BINARY_DIR}/output/${ARG_NAME}-${PROJECT_VERSION}-py3-none-any.whl"
    )

    cmake_policy(SET CMP0116 OLD)
    set(TARGET "${CMAKE_CURRENT_BINARY_DIR}/python-${ARG_NAME}-build.d")
    cmake_path(RELATIVE_PATH TARGET BASE_DIRECTORY "${CMAKE_BINARY_DIR}")
    add_custom_command(
        OUTPUT
        "${CMAKE_CURRENT_BINARY_DIR}/python-${ARG_NAME}-build.d"

        DEPENDS
        "${ARG_BUILD_DIR}/test-${ARG_NAME}-python"
        "${MODULE_PATH}/python/setup.py"
        "${MODULE_PATH}/python/depfile.py"

        DEPFILE
        "${CMAKE_CURRENT_BINARY_DIR}/python-${ARG_NAME}-build.d"

        COMMAND
        ${SET_ENV_VAR}
        "${PYTHON3_BIN}" "${MODULE_PATH}/python/setup.py"

        "build_scripts"
        "--executable=${PYTHON3_BIN}"

        "egg_info"
        "--egg-base" "${ARG_BUILD_DIR}/build"

        "build"
        "--build-base=${ARG_BUILD_DIR}/build/build"
        "--build-lib=${ARG_BUILD_DIR}/build/build/lib"
        "--build-scripts=${ARG_BUILD_DIR}/build/build/scripts"
        ${DEBUG_FLAG}

        COMMAND
        "${PYTHON3_BIN}" "${MODULE_PATH}/python/depfile.py"

        "--target" "${TARGET}"
        "--sources" "${ARG_BUILD_DIR}/build/${ARG_NAME}.egg-info/SOURCES.txt"
        "--output" "${CMAKE_CURRENT_BINARY_DIR}/python-${ARG_NAME}-build.d"

        WORKING_DIRECTORY "${ARG_SRC_DIR}"
    )
    add_custom_target(
        ${ARG_NAME}-py ALL
        DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/python-${ARG_NAME}-build.d"
    )
endfunction()

function(test_python_package)
    cmake_parse_arguments(
        ARG
        ""
        "NAME;PACKAGE;TIMEOUT;PATH;TEST;PYTHONPATH"
        "ENVIRONMENT"
        ${ARGN}
    )
    find_program(PYTHON3_BIN "python3" REQUIRED)
    add_test(
        NAME ${ARG_NAME} COMMAND

        "/bin/sh"
        "-c"
        "${ARG_TEST}"

        WORKING_DIRECTORY ${WHEEL_${ARG_PACKAGE}_BUILD_DIR}
    )
    if (NOT ARG_TIMEOUT)
        set(ARG_TIMEOUT 900)
    endif()
    string(
        JOIN
        ";"
        EXTRA_ENV
        "PYTHONPATH=${WHEEL_${ARG_PACKAGE}_BUILD_DIR}/build/lib:${ARG_PYTHONPATH}:$ENV{PYTHONPATH}"
        "PYTHONUNBUFFERED=1"
        "PATH=${WHEEL_${ARG_PACKAGE}_BUILD_DIR}/build/scripts:${ARG_PATH}:$ENV{PATH}"
        ${ARG_ENVIRONMENT}
    )
    set_tests_properties(
        ${ARG_NAME}
        PROPERTIES
        ENVIRONMENT "${EXTRA_ENV}"
        TIMEOUT ${ARG_TIMEOUT}
    )
endfunction()
