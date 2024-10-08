function(download_custom_release_file)
    cmake_parse_arguments(
        ARG
        ""
        "OWNER;PROJECT;VERSION;FILE;OUTPUT_TARGET_NAME"
        ""
        ${ARGN}
    )
    string(MD5 HASH "${CMAKE_BINARY_DIR}/assets/${ARG_FILE}")
    set(TARGET_NAME "download-asset-${HASH}")
    set("${ARG_OUTPUT_TARGET_NAME}" "${TARGET_NAME}" CACHE INTERNAL "${PROJECT} asset target name")
    if (NOT TARGET ${TARGET_NAME})
        add_custom_command(
            OUTPUT
            "${CMAKE_BINARY_DIR}/assets/${ARG_FILE}"

            COMMAND
            gh release download v${ARG_VERSION} --repo ${ARG_OWNER}/${ARG_PROJECT} --pattern "${ARG_FILE}"

            WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/assets"
        )
        add_custom_target(
            "${TARGET_NAME}"
            DEPENDS "${CMAKE_BINARY_DIR}/assets/${ARG_FILE}"
        )
    endif()
endfunction()

function(download_release_file)
    cmake_parse_arguments(
        ARG
        ""
        "PROJECT;VERSION;FILE;OUTPUT_TARGET_NAME"
        ""
        ${ARGN}
    )
    download_custom_release_file(
        OWNER "featuremine"
        PROJECT ${ARG_PROJECT}
        VERSION ${ARG_VERSION}
        FILE ${ARG_FILE}
        OUTPUT_TARGET_NAME ${ARG_OUTPUT_TARGET_NAME}
    )
endfunction()

macro(add_py_file SRC DST)
  add_custom_command(
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/dist/${DST}"
    COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_CURRENT_SOURCE_DIR}/${SRC}" "${CMAKE_CURRENT_BINARY_DIR}/dist/${DST}"
    DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/${SRC}"
  )
  list(APPEND PY_FILES "${CMAKE_CURRENT_BINARY_DIR}/dist/${DST}")
endmacro()

function(get_python_platform OUTPUT_VARIABLE)
    if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        set(${OUTPUT_VARIABLE} "manylinux_2_17_${CMAKE_SYSTEM_PROCESSOR}" PARENT_SCOPE)
    elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
        execute_process(
            COMMAND sw_vers -productVersion
            OUTPUT_VARIABLE MACOS_VERSION
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        STRING(REGEX REPLACE "^([0-9]+)\\.?([0-9]+)\\.?([0-9]+)?$" "\\1" MACOS_VERSION_MAJOR "${MACOS_VERSION}")
        STRING(REGEX REPLACE "^([0-9]+)\\.?([0-9]+)\\.?([0-9]+)?$" "\\2" MACOS_VERSION_MINOR "${MACOS_VERSION}")
        set(${OUTPUT_VARIABLE} "macosx_${MACOS_VERSION_MAJOR}_0_${CMAKE_SYSTEM_PROCESSOR}" PARENT_SCOPE)
    elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(${OUTPUT_VARIABLE} "win_${CMAKE_SYSTEM_PROCESSOR}" PARENT_SCOPE)
    else()
        message(FATAL_ERROR "Platform not supported")
    endif()
endfunction()
