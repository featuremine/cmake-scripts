set(CMAKE_POLICY_DEFAULT_CMP0077 NEW)

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
        if (NOT EXISTS "${DEP_SRC_DIR}")
            find_package(Git REQUIRED)
            message(STATUS "Downloading ${ARG_NAME} ${ARG_VERSION} ${ARG_GIT_REVISION}")
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
        set(CMAKE_EXE_LINKER_FLAGS "-static-libstdc++ -static-libgcc")
        add_subdirectory("${DEP_SRC_DIR}" "${DEP_BIN_DIR}" EXCLUDE_FROM_ALL)
        unset(CMAKE_EXE_LINKER_FLAGS)
        unset(BUILD_SHARED_LIBS)
        unset(BUILD_TESTING)
        unset(BUILD_API_DOCS)
        foreach(VAR_NAME IN LISTS ARG_VARIABLES)
            get_directory_property(${VAR_NAME} DIRECTORY "${DEP_SRC_DIR}" DEFINITION ${VAR_NAME})
            set(${VAR_NAME} ${${VAR_NAME}} PARENT_SCOPE)
        endforeach()
    endif()
    if (ARG_VERSION OR ARG_VERSION_MIN OR ARG_VERSION_MAX)
        set(original_proj_ver ${PROJECT_VERSION})
        set(PROJECT_VERSION "UNKNOWN")
        get_directory_property(${ARG_NAME}_VERSION DIRECTORY "${${ARG_NAME}_SOURCE_DIR}" DEFINITION PROJECT_VERSION)
        set(${ARG_NAME}_VERSION ${${ARG_NAME}_VERSION} PARENT_SCOPE)
        set(PROJECT_VERSION ${original_proj_ver})
        if (ARG_VERSION AND NOT ${${ARG_NAME}_VERSION} VERSION_EQUAL "${ARG_VERSION}")
            message(FATAL_ERROR "${ARG_NAME} expected version ${ARG_VERSION}, got ${${ARG_NAME}_VERSION}")
        elseif (ARG_VERSION_MIN AND NOT ${${ARG_NAME}_VERSION} VERSION_GREATER_EQUAL "${ARG_VERSION_MIN}")
            message(FATAL_ERROR "${ARG_NAME} expected at least version ${ARG_VERSION_MIN}, got ${${ARG_NAME}_VERSION}")
        elseif (ARG_VERSION_MAX AND NOT ${${ARG_NAME}_VERSION} VERSION_LESS "${ARG_VERSION_MAX}")
            message(FATAL_ERROR "${ARG_NAME} expected version less than ${ARG_VERSION_MAX}, got ${${ARG_NAME}_VERSION}")
        endif ()
    endif ()
    message(STATUS "Using ${ARG_NAME} ${${ARG_NAME}_VERSION}")
endfunction()
