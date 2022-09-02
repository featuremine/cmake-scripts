set(MODULE_PATH ${CMAKE_CURRENT_LIST_DIR})

function(self_extracting_package)
    cmake_parse_arguments(
        ARG
        ""
        "NAME;PACKAGE_DIR"
        "FILES"
        ${ARGN}
    )
    add_custom_command(
        OUTPUT
        "${CMAKE_CURRENT_BINARY_DIR}/${ARG_NAME}.tar.gz"

        COMMAND
        ${CMAKE_COMMAND} -E
        tar
        "czvf" "${CMAKE_CURRENT_BINARY_DIR}/${ARG_NAME}.tar.gz"
        ${ARG_FILES}

        COMMENT
        "Compressing ${ARG_NAME}.tar.gz"

        WORKING_DIRECTORY
        "${ARG_PACKAGE_DIR}"

        DEPENDS
        ${ARG_FILES}
    )
    add_custom_command(
        OUTPUT
        "${CMAKE_BINARY_DIR}/output/${ARG_NAME}-${PROJECT_VERSION}.sh"

        COMMAND
        "${CMAKE_COMMAND}" -E env
        "PROJECT_NAME=${PROJECT_NAME}"
        "PROJECT_VERSION=${PROJECT_VERSION}"

        "sh"
        "${MODULE_PATH}/install/gen_installer.sh"
        "${MODULE_PATH}/install/installer.sh"
        "${CMAKE_CURRENT_BINARY_DIR}/${ARG_NAME}.tar.gz"
        "${CMAKE_BINARY_DIR}/output/${ARG_NAME}-${PROJECT_VERSION}.sh"

        COMMENT
        "Generating installer output/${ARG_NAME}-${PROJECT_VERSION}.sh"

        WORKING_DIRECTORY
        "${ARG_PACKAGE_DIR}"

        DEPENDS
        "${MODULE_PATH}/install/gen_installer.sh"
        "${MODULE_PATH}/install/installer.sh"
        "${CMAKE_CURRENT_BINARY_DIR}/${ARG_NAME}.tar.gz"
    )

    add_custom_target(
        ${ARG_NAME}-package ALL

        COMMENT
        "Ready output/${ARG_NAME}-${PROJECT_VERSION}.sh"

        DEPENDS
        "${CMAKE_BINARY_DIR}/output/${ARG_NAME}-${PROJECT_VERSION}.sh"
    )
endfunction()
