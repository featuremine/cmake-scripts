function(add_subproject)
    cmake_parse_arguments(
        ARG
        ""
        "NAME;VERSION;GIT_REVISION;GIT_URL"
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
        if (NOT EXISTS "${DEP_SRC_DIR}")
            find_package(Git REQUIRED)
            message(VERBOSE "Downloading ${ARG_NAME} ${ARG_VERSION} ${ARG_GIT_REVISION}")
            execute_process(
                COMMAND
                "${GIT_EXECUTABLE}"
                "clone"
                "--depth"
                "1"
                "-b"
                "${ARG_GIT_REVISION}"
                "${ARG_GIT_URL}"
                "${DEP_SRC_DIR}"
                RESULT_VARIABLE ret
                ERROR_VARIABLE stderr
            )
            if(ret AND NOT ret EQUAL 0)
                message(FATAL_ERROR "git clone ${DEP_REPO} failed: ${stderr}")
            endif()
        endif()
        set(BUILD_SHARED_LIBS OFF)
        set(BUILD_TESTING OFF)
        set(BUILD_API_DOCS OFF)
        add_subdirectory("${DEP_SRC_DIR}" "${DEP_BIN_DIR}" EXCLUDE_FROM_ALL)
        unset(BUILD_SHARED_LIBS)
        unset(BUILD_TESTING)
        unset(BUILD_API_DOCS)
        foreach(VAR_NAME IN LISTS ARG_VARIABLES)
            get_directory_property(${VAR_NAME} DIRECTORY "${DEP_SRC_DIR}" DEFINITION ${VAR_NAME})
        endforeach()
    endif()
    if (ARG_VERSION)
        set(original_proj_ver ${PROJECT_VERSION})
        set(PROJECT_VERSION "UNKNOWN")
        get_directory_property(${ARG_NAME}_VERSION DIRECTORY "${${ARG_NAME}_SOURCE_DIR}" DEFINITION PROJECT_VERSION)
        set(PROJECT_VERSION ${original_proj_ver})
        if (NOT ${${ARG_NAME}_VERSION} STREQUAL "${ARG_VERSION}")
            message(FATAL_ERROR "${ARG_NAME} expected version ${ARG_VERSION}, got ${${ARG_NAME}_VERSION}")
        endif ()
    endif ()
    message(VERBOSE "Using ${ARG_NAME} ${${ARG_NAME}_VERSION}")
endfunction()
