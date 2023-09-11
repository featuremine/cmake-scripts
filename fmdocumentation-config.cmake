#[===[
        COPYRIGHT (c) 2019-2023 by Featuremine Corporation.

        This Source Code Form is subject to the terms of the Mozilla Public
        License, v. 2.0. If a copy of the MPL was not distributed with this
        file, You can obtain one at https://mozilla.org/MPL/2.0/.
]===]

set(MODULE_PATH ${CMAKE_CURRENT_LIST_DIR})

function(add_documentation)
    find_program(PYTHON3_BIN "python3")

    if (NOT BUILD_DOCUMENTATION_FORCE)
        if (PYTHON3_BIN-NOTFOUND)
            message(WARNING "Unable to build documentation: python3 not found")
            return()
        endif()
        execute_process(COMMAND ${PYTHON3_BIN} -c "import pandoc" RESULT_VARIABLE ret)
        if (NOT ret EQUAL "0")
            message(WARNING "Unable to build documentation: python module pandoc not found")
            return()
        endif()
    endif()
    if (PYTHON3_BIN-NOTFOUND)
        message(FATAL_ERROR "Unable to build documentation: python3 not found")
    endif()

    cmake_parse_arguments(
        ARG
        ""
        "NAME;BUILD_DIR;SRC_DIR;TITLE;VERSION"
        "DEPENDS"
        ${ARGN}
    )
    cmake_policy(SET CMP0116 OLD)
    add_custom_command(
        OUTPUT
        "${CMAKE_BINARY_DIR}/output/${ARG_NAME}-${ARG_VERSION}-html.tar.gz"
        "${CMAKE_BINARY_DIR}/output/${ARG_NAME}-${ARG_VERSION}-md.tar.gz"

        DEPFILE
        "${CMAKE_CURRENT_BINARY_DIR}/${ARG_NAME}.d"

        COMMENT
        "Compressing ${ARG_NAME}.html"

        COMMAND
        ${PYTHON3_BIN} "${MODULE_PATH}/python/build-doc.py"
        "--builddir" "${ARG_BUILD_DIR}"
        "--srcdir" "${ARG_SRC_DIR}"
        "--depfile" "${CMAKE_CURRENT_BINARY_DIR}/${ARG_NAME}.d"
        "--target" "output/${ARG_NAME}-${ARG_VERSION}-html.tar.gz"
        "--htmloutput" "${CMAKE_BINARY_DIR}/output/${ARG_NAME}-${ARG_VERSION}-html.tar.gz"
        "--mdoutput" "${CMAKE_BINARY_DIR}/output/${ARG_NAME}-${ARG_VERSION}-md.tar.gz"
        "--title" "${ARG_TITLE}"
        "--cmake" "${CMAKE_COMMAND}"

        DEPENDS
        "${MODULE_PATH}/python/build-doc.py"
        ${ARG_DEPENDS}
    )
    add_custom_target(
        ${ARG_NAME} ALL

        COMMENT
        "Ready ${CMAKE_BINARY_DIR}/output/${ARG_NAME}.html"

        DEPENDS
        "${CMAKE_BINARY_DIR}/output/${ARG_NAME}-${ARG_VERSION}-html.tar.gz"
        "${CMAKE_BINARY_DIR}/output/${ARG_NAME}-${ARG_VERSION}-md.tar.gz"
    )
endfunction()
