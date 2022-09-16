function(python_package)
    cmake_parse_arguments(
        ARG
        ""
        "NAME;SRC_DIR;BUILD_DIR"
        ""
        ${ARGN}
    )
    find_program(PYTHON3_BIN "python3" REQUIRED)
    file(GLOB_RECURSE PYTHON_FILES "${ARG_SRC_DIR}/*")
    if(CMAKE_BUILD_TYPE MATCHES DEBUG)
        set(DEBUG_FLAG "--debug")
    endif()
    execute_process(COMMAND ${PYTHON3_BIN} -c "import sys;sys.stdout.write('scripts-%d.%d' % sys.version_info[:2])" OUTPUT_VARIABLE PYTHON3_SCRIPTS_DIR)
    set(WHEEL_${ARG_NAME}_BUILD_DIR ${ARG_BUILD_DIR} PARENT_SCOPE)
    set(WHEEL_${ARG_NAME}_SCRIPTS_DIR ${PYTHON3_SCRIPTS_DIR} PARENT_SCOPE)
    add_custom_command(
        OUTPUT
        "${CMAKE_BINARY_DIR}/output/${ARG_NAME}-${PROJECT_VERSION}-py3-none-any.whl"

        DEPENDS
        ${PYTHON_FILES}

        COMMAND
        "${PYTHON3_BIN}" "setup.py"

        "build"
        "--build-base=${ARG_BUILD_DIR}/build"
        ${DEBUG_FLAG}

        "egg_info"
        "--egg-base" "${ARG_BUILD_DIR}"

        "bdist_wheel"
        "--bdist-dir=${ARG_BUILD_DIR}/bdist"
        "--dist-dir=${CMAKE_BINARY_DIR}/output"

        COMMAND
        "${PYTHON3_BIN}" "setup.py"

        "build_scripts"
        "--executable=${PYTHON3_BIN}"
        "-f"

        "build"
        "--build-base=${ARG_BUILD_DIR}/build"
        ${DEBUG_FLAG}

        WORKING_DIRECTORY "${ARG_SRC_DIR}"
    )
    add_custom_target(
        ${ARG_NAME}-whl ALL
        DEPENDS "${CMAKE_BINARY_DIR}/output/${ARG_NAME}-${PROJECT_VERSION}-py3-none-any.whl"
    )
endfunction()

function(test_python_package)
    cmake_parse_arguments(
        ARG
        ""
        "NAME;PACKAGE;TIMEOUT;YAMALCOMPPATH;TEST"
        ""
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
    set_tests_properties(
        ${ARG_NAME}
        PROPERTIES
        ENVIRONMENT "YAMALCOMPPATH=${ARG_YAMALCOMPPATH};PYTHONPATH=${WHEEL_${ARG_PACKAGE}_BUILD_DIR}/build/lib:$ENV{PYTHONPATH}:$ENV{PYTHONPATH};TEST_OUTPUT_DIR=${WHEEL_${ARG_PACKAGE}_BUILD_DIR};LICENSE_PATH=${LICENSE_PATH};PYTHONUNBUFFERED=1;PATH=${WHEEL_${ARG_PACKAGE}_BUILD_DIR}/build/${WHEEL_${ARG_PACKAGE}_SCRIPTS_DIR}:$ENV{PATH}"
        TIMEOUT ${ARG_TIMEOUT}
    )
endfunction()
