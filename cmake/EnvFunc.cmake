# Guard -----------------------------------------------------------------------

if (ENV_FUNCTIONS_INCLUDED)
    return()
endif ()

set(ENV_FUNCTIONS_INCLUDED TRUE)


# TODO: fix diamond dependencies


# Names -----------------------------------------------------------------------

function(env_prefix _name _prefix _out)
    string(REGEX MATCH "^${_prefix}" _match ${_name})
    if (_name AND NOT _match)
        set(${_out} "${_prefix}_${_name}" PARENT_SCOPE)
    elseif (_match)
        set(${_out} "${_name}" PARENT_SCOPE)
    else ()
        set(${_out} "${_prefix}" PARENT_SCOPE)
    endif ()
endfunction()

function(env_suffix _name _suffix _out)
    string(REGEX MATCH "${_suffix}\$" _match ${_name})
    if (_name AND NOT _match)
        set(${_out} "${_name}_${_suffix}" PARENT_SCOPE)
    elseif (_match)
        set(${_out} "${_name}" PARENT_SCOPE)
    else ()
        set(${_out} "${_suffix}" PARENT_SCOPE)
    endif ()
endfunction()


set(__env_delimiter_regex
    [[\.|-|_|/|\\|::]]
    CACHE STRING
    "Matches delimiters."
    FORCE)

function(env_use_upper_project_name)
    string(TOUPPER ${PROJECT_NAME} _upper)
    string(REGEX REPLACE ${__env_delimiter_regex} [[_]] _upper ${_upper})
    set(UPPER_PROJECT_NAME ${_upper} PARENT_SCOPE)
endfunction()

function(env_use_lower_project_name)
    string(TOLOWER ${PROJECT_NAME} _lower)
    string(REGEX REPLACE ${__env_delimiter_regex} [[_]] _lower ${_lower})
    set(LOWER_PROJECT_NAME ${_lower} PARENT_SCOPE)
endfunction()


function(env_prefix_with_project_name _name _out)
    env_use_lower_project_name()
    env_prefix(${_name} ${LOWER_PROJECT_NAME} _prefixed)
    set(${_out} ${_prefixed} PARENT_SCOPE)
endfunction()


function(env_target_name_for _path _out)
    string(REGEX MATCH [[\..*$]] _extension "${_path}")
    file(RELATIVE_PATH _relative "${PROJECT_SOURCE_DIR}" "${_path}")

    string(REPLACE "${_extension}" "" _name "${_relative}")
    string(REGEX REPLACE / _ _name "${_name}")

    env_use_lower_project_name()
    set(${_out} ${LOWER_PROJECT_NAME}_${_name} PARENT_SCOPE)
endfunction()


# Logging ---------------------------------------------------------------------

if (CMAKE_BUILD_TYPE STREQUAL Debug)
    option(ENV_LOG_VERBOSE
           "Turn on verbose CMake logging."
           ON)
else ()
    option(ENV_LOG_VERBOSE
           "Turn on verbose CMake logging."
           OFF)
endif ()

set(__env_verbose_message_levels
    "\
STATUS;VERBOSE;DEBUG;TRACE\
"
    CACHE STRING
    "Message levels considered verbose by the environment."
    FORCE)

set(__env_message_levels
    "\
FATAL_ERROR;SEND_ERROR;WARNING;AUTHOR_WARNING;DEPRECATION;NOTICE;\
${env_verbose_message_levels}\
"
    CACHE_STRING
    "Valid message levels for environment."
    FORCE)

if (ENV_LOG_VERBOSE)
    function(env_log _level)
        list(FIND __env_message_levels ${_level} _index)

        list(JOIN ARGN " " _message)
        env_use_lower_project_name()
        if (NOT _index EQUAL -1)
            message(${_level} "[env::${LOWER_PROJECT_NAME}]: ${_message}")
        else ()
            message(STATUS "[env::${LOWER_PROJECT_NAME}]: ${_level} ${_message}")
        endif ()
    endfunction()
else ()
    function(env_log _level)
        list(FIND __env_verbose_message_levels ${_level} _index)

        list(JOIN ARGN " " _message)
        if (NOT _index EQUAL -1)
            env_use_lower_project_name()
            message(${_level} "[env::${LOWER_PROJECT_NAME}]: ${_message}")
        endif ()
    endfunction()
endif ()


# Compiler --------------------------------------------------------------------

# TODO: Intel compiler support

env_log(Compiler ID is: \"${CMAKE_CXX_COMPILER_ID}\".)
env_log(MSVC is present: ${MSVC})

if (CMAKE_CXX_COMPILER_ID STREQUAL Clang)
    if (MSVC)
        env_log(Detected ClangCl compiler.)
        set(ENV_CLANG_CL TRUE CACHE BOOL "Whether CLANG_CL was detected or not.")
        set(ENV_MSVC FALSE CACHE BOOL "Whether MSVC was detected or not.")
        set(ENV_GCC FALSE CACHE BOOL "Whether GCC was detected or not.")
        set(ENV_CLANG FALSE CACHE BOOL "Whether Clang was detected or not.")
    else ()
        env_log(Detected Clang compiler.)
        set(ENV_CLANG_CL FALSE CACHE BOOL "Whether CLANG_CL was detected or not.")
        set(ENV_MSVC FALSE CACHE BOOL "Whether MSVC was detected or not.")
        set(ENV_GCC FALSE CACHE BOOL "Whether GCC was detected or not.")
        set(ENV_CLANG TRUE CACHE BOOL "Whether Clang was detected or not.")
    endif ()

elseif (MSVC) # for some reason "CMAKE_CXX_COMPILER_ID STREQUAL MSVC" doesn't work
    env_log(Detected MSVC compiler.)
    set(ENV_CLANG_CL FALSE CACHE BOOL "Whether CLANG_CL was detected or not.")
    set(ENV_MSVC TRUE CACHE BOOL "Whether MSVC was detected or not.")
    set(ENV_GCC FALSE CACHE BOOL "Whether GCC was detected or not.")
    set(ENV_CLANG FALSE CACHE BOOL "Whether Clang was detected or not.")

elseif (CMAKE_CXX_COMPILER_ID STREQUAL GNU)
    env_log(Detected GCC compiler.)
    set(ENV_CLANG_CL FALSE CACHE BOOL "Whether CLANG_CL was detected or not.")
    set(ENV_MSVC FALSE CACHE BOOL "Whether MSVC was detected or not.")
    set(ENV_GCC TRUE CACHE BOOL "Whether GCC was detected or not.")
    set(ENV_CLANG FALSE CACHE BOOL "Whether Clang was detected or not.")

else ()
    env_log(Unknown compiler.)
    set(ENV_CLANG_CL FALSE CACHE BOOL "Whether CLANG_CL was detected or not.")
    set(ENV_MSVC FALSE CACHE BOOL "Whether MSVC was detected or not.")
    set(ENV_GCC FALSE CACHE BOOL "Whether GCC was detected or not.")
    set(ENV_CLANG FALSE CACHE BOOL "Whether Clang was detected or not.")

endif ()


# Sources ---------------------------------------------------------------------

function(env_target_link _name)
    env_prefix_with_project_name(${_name} _mod)
    env_log(Linking \"${_name}\" with \"${ARGN}\".)

    target_link_libraries(${_mod} ${ARGN})
endfunction()

function(env_target_include _name)
    env_prefix_with_project_name(${_name} _mod)
    env_log(Into \"${_name}\" including \"${ARGN}\".)

    target_include_directories(${_mod} ${ARGN})
endfunction()

function(env_target_sources _name)
    env_prefix_with_project_name(${_name} _mod)
    env_log(Sourcing \"${_name}\" with \"${ARGN}\".)

    target_sources(${_mod} ${ARGN})
endfunction()


# Properties ------------------------------------------------------------------

function(env_target_set _name)
    env_prefix_with_project_name(${_name} _mod)
    env_log(On \"${_name}\" setting \"${ARGN}\".)

    set_target_properties(${_mod} PROPERTIES ${ARGN})
endfunction()

include(CheckIPOSupported)
check_ipo_supported(RESULT __env_ipo_supported)
if (__env_ipo_supported)
    env_log(Interprocedural optimization is supported.)

    function(env_target_set_ipo _name)
        env_target_set(${_name} INTERPROCEDURAL_OPTIMIZATION ON)
    endfunction()
else ()
    env_log(Interprocedural optimization is not supported.)

    function(env_target_set_ipo _name)
    endfunction()
endif ()

include(CheckPIESupported)
check_pie_supported(OUTPUT_VARIABLE __env_pie_supported LANGUAGES CXX)
if (__env_pie_supported)
    env_log(Position independent code is supported.)

    function(env_target_set_pie _name)
        env_target_set(${_name} POSITION_INDEPENDENT_CODE ON)
    endfunction()
else ()
    env_log(Position independent code is not supported.)

    function(env_target_set_pie _name)
    endfunction()
endif ()


# Flags -----------------------------------------------------------------------

function(env_target_link_with _name)
    env_prefix_with_project_name(${_name} _mod)
    env_log(On \"${_name}\" adding link options \"${ARGN}\".)

    target_link_options(${_mod} ${ARGN})
endfunction()

function(env_target_compile_with _name _visibility)
    env_prefix_with_project_name(${_name} _mod)
    env_log(On \"${_name}\" adding compile options \"${ARGN}\".)

    target_compile_options(${_mod} ${ARGN})
endfunction()

include(CheckCXXCompilerFlag)
function(env_target_safely_compile_with _name _visibility)
    env_prefix_with_project_name(${_name} _mod)
    env_log(On \"${_name}\" adding compile options \"${ARGN}\".)

    foreach (_flag IN LISTS ARGN)
        check_compiler_flag(CXX ${_flag} _supported)
        if (_supported)
            target_compile_options(${_mod} ${_visibility} ${_flag})
        else ()
            env_log(WARNING
                    On \"${_name}\" adding compile option \"${_flag}\"
                    FAILED. REASON: Option not supported by compiler.)
        endif ()
    endforeach ()
endfunction()


# Compilation -----------------------------------------------------------------

function(env_target_precompile _name)
    env_prefix_with_project_name(${_name} _mod)
    env_log(Precompiling \"${_name}\" with \"${ARGN}\".)

    target_precompile_headers(${_mod} PRIVATE ${ARGN})
endfunction()

function(env_target_features _name)
    env_prefix_with_project_name(${_name} _mod)
    env_log(Compiling \"${_name}\" with \"${ARGN}\".)

    target_compile_features(${_mod} ${ARGN})
endfunction()

function(env_target_definitions _name)
    env_prefix_with_project_name(${_name} _mod)
    env_log(Compiling \"${_name}\" with \"${ARGN}\".)

    target_compile_definitions(${_mod} ${ARGN})
endfunction()

if (ENV_CLANG_CL)
    function(env_target_conform _name)
        env_log(Setting standards conformance on \"${_name}\".)

        target_compile_options(
                ${_name}
                PRIVATE
                # standards conformance
                /permissive-
                # otherwise we can't detect the C++ standard
                /Zc:__cplusplus
                # MSVC and ClangCL are weird about auto
                /Zc:auto)

        # clang-cl doesn't enable exceptions by default unlike all other
        # compilers

        get_target_property(_options ${_name} COMPILE_OPTIONS)
        if (_options STREQUAL _options-NOTFOUND)
            target_compile_options(${_name} PRIVATE /EHsc)
        else ()
            string(REGEX MATCH [[/EH.*]] _exceptions_enabled ${_options})
            if (NOT _exceptions_enabled)
                target_compile_options(${_name} PRIVATE /EHsc)
            else ()
                env_log(Exceptions already enabled on \"${_name}\".)
            endif ()
        endif ()
    endfunction()
elseif (ENV_MSVC)
    function(env_target_conform _name)
        env_log(Setting standards conformance on \"${_name}\".)

        target_compile_options(
                ${_name}
                PRIVATE
                # standards compliance
                /permissive-
                # otherwise we can't detect the C++ standard
                /Zc:__cplusplus
                # MSVC and ClangCL are weird about auto
                /Zc:auto)
    endfunction()
else ()
    function(env_target_conform _name)
    endfunction()
endif ()

function(env_set_cpp17 _name)
    env_prefix_with_project_name(${_name} _mod)
    env_log(Setting C++17 standard on \"${_name}\".)

    target_compile_features(${_mod} PRIVATE cxx_std_17)
    set_target_properties(${_mod} PROPERTIES CXX_EXTENSIONS OFF)
endfunction()


# Warnings --------------------------------------------------------------------

# TODO: clang analysis
# deeply copy the original target and
# add the deep copy as a dependency with the --analyze flag?

if (ENV_CLANG_CL)
    function(env_target_warn _name)
        env_prefix_with_project_name(${_name} _mod)
        env_log(Adding warnings to \"${_name}\".)

        target_compile_options(
                ${_mod}
                PRIVATE
                /W4 /WX
                # --analyze
        )
    endfunction()
    function(env_target_suppress _name)
        env_log(Suppressing warnings on \"${_name}\".)

        target_compile_options(${_name} PRIVATE /w)
    endfunction()

elseif (ENV_MSVC)
    function(env_target_warn _name)
        env_prefix_with_project_name(${_name} _mod)
        env_log(Adding warnings to \"${_name}\".)

        target_compile_options(${_mod} PRIVATE /W4 /WX /analyze)
    endfunction()
    function(env_target_suppress _name)
        env_log(Suppressing warnings on \"${_name}\".)

        target_compile_options(${_name} PRIVATE /w)
    endfunction()

elseif (ENV_GCC)
    function(env_target_warn _name)
        env_prefix_with_project_name(${_name} _mod)
        env_log("Adding warnings to \"${_name}\".")

        target_compile_options(
                ${_mod}
                PRIVATE
                -Wall -Wextra -Wpedantic -Werror
                -fanalyzer
                # so messages are printed nicely
                -ftrack-macro-expansion=0
                # detect endianness
                -Wno-multichar)
    endfunction()
    function(env_target_suppress _name)
        env_log(Suppressing warnings on \"${_name}\".)

        target_compile_options(${_name} PRIVATE -w)
    endfunction()

elseif (ENV_CLANG)
    function(env_target_warn _name)
        env_prefix_with_project_name(${_name} _mod)
        env_log(Adding warnings to \"${_name}\".)

        target_compile_options(
                ${_mod}
                PRIVATE
                -Wall -Wextra -Wpedantic -Werror
                #                --analyze
        )
    endfunction()
    function(env_target_suppress _name)
        env_log(Suppressing warnings on \"${_name}\".)

        target_compile_options(${_name} PRIVATE -w)
    endfunction()

else ()
    function(env_target_warn)
    endfunction()
    function(env_target_suppress)
    endfunction()

endif ()

set(__env_warning_regex [[/W.*|-W.*]]
    CACHE STRING
    "Regex that matches compiler warning options."
    FORCE)

function(env_target_clear_warn _name)
    env_log(Clearing warnings from \"${_name}\".)

    get_target_property(_options ${_name} COMPILE_OPTIONS)
    if (NOT _options STREQUAL _options-NOTFOUND)
        list(FILTER _options EXCLUDE REGEX ${__env_warning_regex})
        set_target_properties(
                ${_name}
                PROPERTIES
                COMPILE_OPTIONS "${_options}")
    endif ()

    get_target_property(_interface_options ${_name} INTERFACE_COMPILE_OPTIONS)
    if (NOT _interface_options STREQUAL _interface_options-NOTFOUND)
        list(FILTER _interface_options EXCLUDE REGEX ${__env_warning_regex})
        set_target_properties(
                ${_name}
                PROPERTIES
                INTERFACE_COMPILE_OPTIONS "${_interface_options}")
    endif ()
endfunction()


# Optimization ----------------------------------------------------------------

# TODO: sanitization

if (CMAKE_BUILD_TYPE STREQUAL Release OR CMAKE_BUILD_TYPE STREQUAL MinSizeRel)
    if (ENV_CLANG_CL)
        function(env_target_optimize _name)
            env_prefix_with_project_name(${_name} _mod)
            env_log(Adding optimizations to \"${_name}\".)

            target_compile_options(${_mod} PRIVATE /O2)
            env_target_set_ipo(${_name})
        endfunction()
    elseif (ENV_MSVC)
        function(env_target_optimize _name)
            env_prefix_with_project_name(${_name} _mod)
            env_log(Adding optimizations to \"${_name}\".)

            target_compile_options(${_mod} PRIVATE /O2)
            env_target_set_ipo(${_mod})
        endfunction()
    elseif (ENV_GCC)
        function(env_target_optimize _name)
            env_prefix_with_project_name(${_name} _mod)
            env_log(Adding optimizations to \"${_name}\".)

            target_compile_options(${_mod} PRIVATE -O3)
            env_target_set_ipo(${_mod})
        endfunction()
    elseif (ENV_CLANG)
        function(env_target_optimize _name)
            env_prefix_with_project_name(${_name} _mod)
            env_log(Adding optimizations to \"${_name}\".)

            target_compile_options(${_mod} PRIVATE -O3)
            env_target_set_ipo(${_mod})
        endfunction()
    else ()
        function(env_target_optimize _name)
            env_prefix_with_project_name(${_name} _mod)
            env_log(Adding optimizations to \"${_name}\".)

            env_target_set_ipo(${_mod})
        endfunction()
    endif ()
else ()
    if (ENV_CLANG_CL)
        function(env_target_optimize _name)
            env_prefix_with_project_name(${_name} _mod)
            env_log(Adding sanitization to \"${_name}\".)

            target_compile_options(
                    ${_mod}
                    PRIVATE
                    /Zi
                    # -fsanitize=address,undefined
                    # /fsanitize=address
            )
        endfunction()
    elseif (ENV_MSVC)
        function(env_target_optimize _name)
            env_prefix_with_project_name(${_name} _mod)
            env_log(Adding sanitization to \"${_name}\".)

            target_compile_options(
                    ${_mod}
                    PRIVATE
                    /Zi
                    # /fsanitize=address
            )
        endfunction()
    elseif (ENV_GCC)
        function(env_target_optimize _name)
            env_prefix_with_project_name(${_name} _mod)
            env_log(Adding sanitization to \"${_name}\".)

            target_compile_options(
                    ${_mod}
                    PRIVATE
                    -Og
                    -ggdb
                    # -fsanitize=address,leak,undefined
            )
        endfunction()
    elseif (ENV_CLANG)
        function(env_target_optimize _name)
            env_prefix_with_project_name(${_name} _mod)
            env_log(Adding sanitization to \"${_name}\".)

            target_compile_options(
                    ${_mod}
                    PRIVATE
                    -ggdb
                    # -fsanitize=address,undefined
            )
        endfunction()
    else ()
        function(env_target_optimize _name)
        endfunction()
    endif ()
endif ()


# Nonconforming optimization --------------------------------------------------

# TODO: exceptions?

if (ENV_CLANG_CL)
    function(env_target_optimize_nonconforming _name)
        env_prefix_with_project_name(${_name} _mod)
        env_log(Adding nonconforming optimizations to \"${_name}\".)

        target_compile_options(${_mod} PRIVATE /GR-)
    endfunction()
elseif (ENV_MSVC)
    function(env_target_optimize_nonconforming _name)
        env_prefix_with_project_name(${_name} _mod)
        env_log(Adding nonconforming optimizations to \"${_name}\".)

        target_compile_options(${_mod} PRIVATE /GR-)
    endfunction()
elseif (ENV_GCC)
    function(env_target_optimize_nonconforming _name)
        env_prefix_with_project_name(${_name} _mod)
        env_log(Adding nonconforming optimizations to \"${_name}\".)

        target_compile_options(${_mod} PRIVATE -fno-rtti)
    endfunction()
elseif (ENV_CLANG)
    function(env_target_optimize_nonconforming _name)
        env_prefix_with_project_name(${_name} _mod)
        env_log(Adding nonconforming optimizations to \"${_name}\".)

        target_compile_options(${_mod} PRIVATE -fno-rtti)
    endfunction()
else ()
    function(env_target_optimize_nonconforming _name)
    endfunction()
endif ()


# Atomic targets --------------------------------------------------------------

function(env_project_pch)
    env_prefix_with_project_name(pch _mod)
    env_log(" - Adding precompiled headers of \"${PROJECT_NAME}\". - ")

    set(_pch_dir "${PROJECT_SOURCE_DIR}/pch")
    set(_project_pch_dir "${_pch_dir}/${LOWER_PROJECT_NAME}")
    file(GLOB_RECURSE _sources "${_project_pch_dir}/src/*.cpp")

    add_library(${_mod} STATIC ${_sources})
    add_library(${LOWER_PROJECT_NAME}::pch ALIAS ${_mod})

    env_target_link(${_mod} PUBLIC ${ARGN})
    env_target_include(${_mod} PUBLIC "${_pch_dir}")
    env_target_precompile(${_mod} PUBLIC "${_project_pch_dir}/pch.hpp")

    env_target_conform(${_mod})
    env_target_suppress(${_mod})
    env_target_optimize(${_mod})

    env_target_set_pie(${_mod})
    env_set_cpp17(${_mod})
endfunction()

function(env_add_executable _name)
    env_prefix_with_project_name(${_name} _mod)
    env_log("Adding executable \"${_name}\".")

    add_executable(${_mod} ${ARGN})

    env_target_link(${_mod} PRIVATE ${LOWER_PROJECT_NAME}::pch)
    env_target_include(${_mod} PRIVATE ${PROJECT_SOURCE_DIR}/include)

    env_target_conform(${_mod})
    env_target_warn(${_mod})
    env_target_optimize(${_mod})

    env_set_cpp17(${_mod})
endfunction()

function(env_add_library _name)
    env_prefix_with_project_name(${_name} _mod)
    env_log("Adding library \"${_name}\".")

    add_library(${_mod} ${ARGN})

    env_target_link(${_mod} PRIVATE ${LOWER_PROJECT_NAME}::pch)
    env_target_include(${_mod} PRIVATE ${PROJECT_SOURCE_DIR}/include)

    env_target_conform(${_mod})
    env_target_warn(${_mod})
    env_target_optimize(${_mod})

    env_target_set_pie(${_mod})
    env_set_cpp17(${_mod})
endfunction()

function(env_add_interface _name)
    env_prefix_with_project_name(${_name} _mod)
    env_log("Adding interface \"${_name}\".")

    add_library(${_mod} INTERFACE)

    env_target_link(${_mod} INTERFACE ${ARGN})
endfunction()

function(env_add_import _name)
    env_prefix_with_project_name(${_name} _mod)
    env_log("Adding import \"${_name}\".")

    add_library(${_mod} INTERFACE IMPORTED GLOBAL)

    env_target_link(${_mod} INTERFACE ${ARGN})
endfunction()

function(env_add_alias _name)
    env_prefix_with_project_name(${_name} _mod)
    env_log("Adding alias \"${LOWER_PROJECT_NAME}::${_name}\".")

    add_library(${LOWER_PROJECT_NAME}::${_name} ALIAS ${_mod})
endfunction()


# Compound targets ------------------------------------------------------------

function(env_add_dep _name)
    env_log(" - Adding dependency \"${_name}\". - ")

    foreach (_link IN LISTS ARGN)
        get_target_property(_type ${_link} TYPE)
        if (NOT _type STREQUAL INTERFACE_LIBRARY)
            env_target_clear_warn(${_link})
            env_target_suppress(${_link})

            env_target_conform(${_link})
        endif ()
    endforeach ()

    env_add_import(${_name} ${ARGN})
    env_add_alias(${_name})
endfunction()

enable_testing()
include(GoogleTest)

function(env_add_test _name)
    env_use_upper_project_name()
    if (${UPPER_PROJECT_NAME}_BUILD_TESTS)
        env_log(" - Adding test \"${_name}\". - ")

        env_add_executable(${_name} ${ARGN})

        env_use_lower_project_name()
        env_prefix(${_name} ${LOWER_PROJECT_NAME} _mod)
        gtest_discover_tests(${_name})
    endif ()
endfunction()

function(env_add_bench _name)
    env_use_upper_project_name()
    if (NOT CMAKE_BUILD_TYPE STREQUAL Debug AND
        ${UPPER_PROJECT_NAME}_BUILD_BENCHMARKS)

        env_log(" - Adding bench \"${_name}\". - ")

        env_add_executable(${_name} ${ARGN})
    endif ()
endfunction()

function(env_add_static _name)
    env_use_upper_project_name()
    if (${UPPER_PROJECT_NAME}_BUILD_STATIC)
        env_log(- Adding static \"${_name}\". -)

        env_add_library(${_name} STATIC ${ARGN})
        env_add_alias(${_name})
    endif ()
endfunction()

function(env_add_shared _name)
    env_use_upper_project_name()
    if (${UPPER_PROJECT_NAME}_BUILD_SHARED)
        env_log(- Adding shared \"${_name}\". -)

        env_add_library(${_name} SHARED ${ARGN})
        env_add_alias(${_name})
    endif ()
endfunction()

function(env_add_app _name)
    env_use_upper_project_name()
    if (${UPPER_PROJECT_NAME}_BUILD_APPS)
        env_log(" - Adding app \"${_name}\". - ")

        env_add_executable(${_name} ${ARGN})
    endif ()
endfunction()

function(env_add_export _name)
    env_log(" - Adding export \"${_name}\". - ")

    env_add_interface(${_name} ${ARGN})
    env_add_alias(${_name})
endfunction()


# Fetch -----------------------------------------------------------------------

include(FetchContent)

set(ENV_FETCH_DIR
    "${CMAKE_SOURCE_DIR}/.fetch"
    CACHE STRING
    "Download directory for fetching dependencies."
    FORCE)

set(ENV_FETCH_BUILD_DIR
    "${PROJECT_BINARY_DIR}/.fetch"
    CACHE STRING
    "Build directory for fetched dependencies."
    FORCE)

set(FETCHCONTENT_BASE_DIR ${ENV_FETCH_DIR})

function(env_fetch _name)
    cmake_parse_arguments(PARSED "" "" "OPTIONS" ${ARGN})


    env_use_lower_project_name()
    env_prefix(${_name} ${LOWER_PROJECT_NAME} _prefixed)
    env_suffix(${_prefixed} fetch _mod)

    set(_src_dir "${ENV_FETCH_DIR}/${_name}")
    set(_bin_dir "${ENV_FETCH_BUILD_DIR}/${_name}/bin")
    set(_sub_dir "${ENV_FETCH_BUILD_DIR}/${_name}/sub")
    set(_populated_file "${ENV_FETCH_DIR}/.process/${_name}.populated")
    set(_lock_file "${ENV_FETCH_DIR}/.process/${_name}.lock")

    set(${_mod}_src_dir "${_src_dir}" PARENT_SCOPE)
    set(${_mod}_bin_dir "${_bin_dir}" PARENT_SCOPE)
    set(${_mod}_sub_dir "${_src_sir}" PARENT_SCOPE)


    file(LOCK "${_lock_file}")
    if (NOT EXISTS "${_populated_file}")
        env_log("Fetching \"${_name}\" into \"${_src_dir}\".")
        fetchcontent_populate(
                ${_mod}
                QUIET
                ${PARSED_UNPARSED_ARGUMENTS}
                SOURCE_DIR "${_src_dir}"
                BINARY_DIR "${_bin_dir}"
                SUBBUILD_DIR "${_sub_dir}")

        file(WRITE "${_populated_file}" YES)
    else ()
        env_log("Already fetched \"${_name}\" into \"${_src_dir}\".")
    endif ()
    file(LOCK "${_lock_file}" RELEASE)


    foreach (_option IN LISTS PARSED_OPTIONS)
        separate_arguments(_option UNIX_COMMAND "${_option}")
        set(${_option} CACHE BOOL "" FORCE)

        env_log(Setting \"${_name}\" option \"${_option}\".)
    endforeach ()


    if (EXISTS "${_src_dir}/CMakeLists.txt")
        env_log(Adding for \"${_name}\" subdirectories
                \"${_src_dir}\",
                \"${_bin_dir}\".)

        set(_previous_log_level ${CMAKE_MESSAGE_LOG_LEVEL})
        set(_previous_log_indent ${CMAKE_MESSAGE_INDENT})

        set(CMAKE_MESSAGE_LOG_LEVEL VERBOSE)
        set(CMAKE_MESSAGE_INDENT "${_previous_log_indent}    ")
        add_subdirectory("${_src_dir}" "${_bin_dir}")

        set(CMAKE_MESSAGE_LOG_LEVEL ${_previous_log_level})
        set(CMAKE_MESSAGE_INDENT ${_previous_log_indent})

    elseif (EXISTS "${_src_dir}/include" AND
            EXISTS "${_src_dir}/src" OR EXISTS "${_src_dir}/source")
        env_log(Adding for \"${_name}\" a static library
                \"${_prefixed}\" with include directory
                \"${_src_dir}/include\".)

        file(GLOB_RECURSE
             _sources
             "${_src_dir}/src/*.cpp"
             "${_src_dir}/src/*.cc"
             "${_src_dir}/src/*.c"
             "${_src_dir}/source/*.cpp"
             "${_src_dir}/source/*.cc"
             "${_src_dir}/source/*.c")

        add_library(${_prefixed} STATIC IMPORTED GLOBAL)
        env_add_alias(${_name})

        target_include_directories(${_prefixed} "${_src_dir}/include")
        target_sources(${_prefixed} ${_sources})

        env_target_conform(${_prefixed})
        env_target_optimize(${_prefixed})
        env_target_suppress(${_prefixed})

        env_target_set_pie(${_prefixed})

    elseif (EXISTS "${_src_dir}/include")
        env_log(Adding for \"${_name}\" an interface library
                \"${_prefixed}\" with include directory
                \"${_src_dir}/include\".)

        add_library(${_prefixed} INTERFACE IMPORTED GLOBAL)
        env_add_alias(${_name})

        target_include_directories(${_prefixed} INTERFACE "${_src_dir}/include")

    else ()
        env_log(Adding for \"${_name}\" an interface library
                \"${_prefixed}\" with include directory
                \"${_src_dir}\".)

        add_library(${_prefixed} INTERFACE IMPORTED GLOBAL)
        env_add_alias(${_name})

        target_include_directories(${_prefixed} INTERFACE "${_src_dir}")
    endif ()
endfunction()


# Bindings --------------------------------------------------------------------

# TODO


# Project declaration ---------------------------------------------------------

function(env_project_initialize)
    env_use_upper_project_name()

    if (CMAKE_BUILD_TYPE STREQUAL Debug)
        option(${UPPER_PROJECT_NAME}_COMPILER_MESSAGES
               "Turn on compiler messages for ${PROJECT_NAME}."
               ON)

    else ()
        option(${UPPER_PROJECT_NAME}_COMPILER_MESSAGES
               "Turn on compiler messages for ${PROJECT_NAME}."
               OFF)

    endif ()


    option(${UPPER_PROJECT_NAME}_BUILD_TESTS
           "Build ${PROJECT_NAME} tests."
           OFF)

    option(${UPPER_PROJECT_NAME}_BUILD_BENCHMARKS
           "Build ${PROJECT_NAME} benchmarks."
           OFF)


    option(${UPPER_PROJECT_NAME}_BUILD_EXAMPLES
           "Build ${PROJECT_NAME} examples."
           OFF)

    option(${UPPER_PROJECT_NAME}_BUILD_DOCS
           "Build ${PROJECT_NAME} docs."
           OFF)


    option(${UPPER_PROJECT_NAME}_BUILD_EXTRAS
           "Build ${PROJECT_NAME} extras."
           OFF)


    option(${UPPER_PROJECT_NAME}_BUILD_STATIC
           "Build ${PROJECT_NAME} static."
           ON)

    option(${UPPER_PROJECT_NAME}_BUILD_SHARED
           "Build ${PROJECT_NAME} shared."
           OFF)

    option(${UPPER_PROJECT_NAME}_BUILD_APPS
           "Build ${PROJECT_NAME} apps."
           OFF)
endfunction()


# Project targets -------------------------------------------------------------

# TODO: run multi-targets somehow
# executable target that runs the dependencies somehow?

function(env_hook _dependency)
    cmake_parse_arguments(PARSED "" "" "INTO" ${ARGN})

    foreach (_target IN LISTS PARSED_INTO)
        if (NOT TARGET ${_target})
            add_custom_target(${_target} DEPENDS ${_dependency})
        else ()
            get_target_property(
                    _dependencies
                    ${_target}
                    MANUALLY_ADDED_DEPENDENCIES)

            list(FIND _dependencies ${_dependency} _index)
            if (_index EQUAL -1)
                add_dependencies(${_target} ${_dependency})
            endif ()
        endif ()
    endforeach ()
endfunction()


function(env_project_tests)
    env_use_upper_project_name()
    if (${UPPER_PROJECT_NAME}_BUILD_TESTS)
        env_log(-!- Adding tests for ${PROJECT_NAME}. -!-)

        file(GLOB_RECURSE
             _tests
             "${PROJECT_SOURCE_DIR}/test/*.cpp")

        env_use_lower_project_name()
        foreach (_test IN LISTS _tests)
            env_target_name_for(${_test} _target)
            env_add_test(${_target} ${_test})

            env_target_link(${_target} PRIVATE ${ARGN})

            env_hook(${_target} INTO ${LOWER_PROJECT_NAME}_tests)
        endforeach ()
    endif ()
endfunction()

function(env_project_benchmarks)
    env_use_upper_project_name()
    if (NOT CMAKE_BUILD_TYPE STREQUAL Debug AND
        ${UPPER_PROJECT_NAME}_BUILD_BENCHMARKS)

        env_log(-!- Adding benchmarks for ${PROJECT_NAME}. -!-)

        file(GLOB_RECURSE
             _benchmarks
             "${PROJECT_SOURCE_DIR}/bench/*.cpp")

        env_use_lower_project_name()
        foreach (_benchmark IN LISTS _benchmarks)
            env_target_name_for(${_benchmark} _target)
            env_add_bench(${_target} ${_benchmark})

            env_target_link(${_target} PRIVATE ${ARGN})

            env_hook(${_target} INTO ${LOWER_PROJECT_NAME}_benchmarks)
        endforeach ()
    endif ()
endfunction()

# TODO: maybe one file per example?

function(env_project_examples)
    env_use_upper_project_name()
    if (${UPPER_PROJECT_NAME}_BUILD_EXAMPLES)
        env_log(-!- Adding examples for ${PROJECT_NAME}. -!-)
        file(GLOB _examples "${PROJECT_SOURCE_DIR}/example/*/CMakeLists.txt")

        foreach (_example IN LISTS _examples)
            env_log(- Adding example with CMakeLists.txt at \"${_example}\". -)
            add_subdirectory("${_example}/..")
        endforeach ()
    endif ()
endfunction()

# TODO: configure Doxygen

function(env_project_docs)
    env_use_upper_project_name()
    if (${UPPER_PROJECT_NAME}_BUILD_DOCS AND
        EXISTS "${PROJECT_SOURCE_DIR}/docs/CMakeLists.txt")

        env_log(-!- Adding docs for ${PROJECT_NAME}. -!-)
        add_subdirectory("${PROJECT_SOURCE_DIR}/docs")
    endif ()
endfunction()

# TODO: CI here?

function(env_project_extras)
    env_use_upper_project_name()
    if (${UPPER_PROJECT_NAME}_BUILD_EXTRAS)
        env_log(-!- Adding extras for ${PROJECT_NAME}. -!-)
        file(GLOB _extras "${PROJECT_SOURCE_DIR}/extra/*/CMakeLists.txt")

        foreach (_extra IN LISTS _extras)
            env_log(- Adding extra with CMakeLists.txt at \"${_extra}\". -)
            add_subdirectory("${_extra}/..")
        endforeach ()
    endif ()
endfunction()

function(env_project_static)
    env_use_upper_project_name()
    if (${UPPER_PROJECT_NAME}_BUILD_STATIC)
        file(GLOB_RECURSE
             _sources
             "${PROJECT_SOURCE_DIR}/src/*.cpp")

        if (_sources)
            env_use_lower_project_name()
            env_add_static(${LOWER_PROJECT_NAME}_static ${_sources})
        endif ()
    endif ()
endfunction()

function(env_project_shared)
    env_use_upper_project_name()
    if (${UPPER_PROJECT_NAME}_BUILD_SHARED)
        file(GLOB_RECURSE
             _sources
             "${PROJECT_SOURCE_DIR}/src/*.cpp")

        if (_sources)
            env_use_lower_project_name()
            env_add_shared(${LOWER_PROJECT_NAME}_shared ${_sources})
        endif ()
    endif ()
endfunction()

function(env_project_apps)
    env_use_upper_project_name()
    if (${UPPER_PROJECT_NAME}_BUILD_APPS)
        env_log(-!- Adding apps for ${PROJECT_NAME}. -!-)

        file(GLOB_RECURSE
             _apps
             "${PROJECT_SOURCE_DIR}/app/*.cpp")

        file(GLOB_RECURSE
             _sources
             "${PROJECT_SOURCE_DIR}/src/*.cpp")

        foreach (_app IN LISTS _apps)
            env_target_name_for(${_app} _target)

            env_add_app(${_target} ${_app} ${_sources})
        endforeach ()
    endif ()
endfunction()

function(env_project_targets)
    cmake_parse_arguments(
            PARSED
            ""
            ""
            "DEPENDENCIES;TEST_DEPENDENCIES;BENCHMARK_DEPENDENCIES"
            ${ARGN})

    env_project_pch(${PARSED_DEPENDENCIES})

    env_project_static()
    env_project_shared()
    env_project_apps()

    env_project_tests(${PARSED_TEST_DEPENDENCIES})
    env_project_benchmarks(${PARSED_BENCHMARK_DEPENDENCIES})

    env_project_examples()
    env_project_docs()

    env_project_extras()
endfunction()


# Project bindings ------------------------------------------------------------

# TODO
