# If platform is Emscripten
if(${CMAKE_SYSTEM_NAME} STREQUAL "Emscripten")
    set(EMSCRIPTEN 1)
endif()

include(CheckCCompilerFlag)
include(CheckCXXCompilerFlag)

# Warning flags macros
macro(ac_add_c_warning_flag WARNINGFLAG WARNING_VAR)
    check_c_compiler_flag("-W${WARNINGFLAG}" HAVE_CW_${WARNING_VAR})
    if(HAVE_CW_${WARNING_VAR})
       set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -W${WARNINGFLAG}")
    endif()
endmacro()

macro(ac_add_cxx_warning_flag WARNINGFLAG WARNING_VAR)
    check_cxx_compiler_flag("-W${WARNINGFLAG}" HAVE_CXXW_${WARNING_VAR})
    if(HAVE_CXXW_${WARNING_VAR})
       set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -W${WARNINGFLAG}")
    endif()
endmacro()

macro(ac_disable_c_warning_flag WARNINGFLAG WARNING_VAR)
    check_c_compiler_flag("-W${WARNINGFLAG}" HAVE_CW_${WARNING_VAR})
    if(HAVE_CW_${WARNING_VAR})
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-${WARNINGFLAG}")
    endif()
endmacro()

macro(ac_disable_cxx_warning_flag WARNINGFLAG WARNING_VAR)
    check_cxx_compiler_flag("-W${WARNINGFLAG}" HAVE_CXXW_${WARNING_VAR})
    if(HAVE_CXXW_${WARNING_VAR})
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-${WARNINGFLAG}")
    endif()
endmacro()


# Strip garbage
if(APPLE)
    string(REGEX REPLACE "-O3" ""
        CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE}")
    string(REGEX REPLACE "-O3" ""
        CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE}")
    set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -O2")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O2")
    set(LINK_FLAGS_RELEASE  "${LINK_FLAGS_RELEASE} -dead_strip")

    # Unify visibility to meet llvm's default (C++-only)
    include(CheckCXXCompilerFlag)
    check_cxx_compiler_flag("-fvisibility-inlines-hidden" SUPPORTS_FVISIBILITY_INLINES_HIDDEN_FLAG)
    if(SUPPORTS_FVISIBILITY_INLINES_HIDDEN_FLAG)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fvisibility-inlines-hidden")
    endif()
elseif(NOT MSVC)
    if(EMSCRIPTEN)
        set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -Os -fdata-sections -ffunction-sections")
        set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -Os -fdata-sections -ffunction-sections")
        if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
            set(LINK_FLAGS_RELEASE  "${LINK_FLAGS_RELEASE} -dead_strip")
        else()
            set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -Wl,--gc-sections -Wl,-s")
            set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -Wl,--gc-sections -Wl,-s")
            set(LINK_FLAGS_RELEASE  "${LINK_FLAGS_RELEASE} -Wl,--gc-sections -Wl,-s")
        endif()
    else()
        string(REGEX REPLACE "-O3" ""
            CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE}")
        string(REGEX REPLACE "-O3" ""
            CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE}")
        set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -O2 -fdata-sections -ffunction-sections")
        set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O2 -fdata-sections -ffunction-sections")
        if(ANDROID)
            set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -funwind-tables")
            set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -funwind-tables")
        elseif(NOT "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
            set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -s -Wl,--gc-sections -Wl,-s")
            set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -s -Wl,--gc-sections -Wl,-s")
            set(LINK_FLAGS_RELEASE  "${LINK_FLAGS_RELEASE} -Wl,--gc-sections -Wl,-s")
        else()
            set(LINK_FLAGS_RELEASE  "${LINK_FLAGS_RELEASE} -dead_strip")
        endif()
    endif()
endif()

# Global optimization flags
if(NOT MSVC)
    set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -fno-omit-frame-pointer")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -fno-omit-frame-pointer")
endif()

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release")
endif()

string(TOLOWER ${CMAKE_BUILD_TYPE} CMAKE_BUILD_TYPE_LOWER)

set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -DNDEBUG")

if(MSVC)
    # Force to always compile with W4
    if(CMAKE_CXX_FLAGS MATCHES "/W[0-4]")
        string(REGEX REPLACE "/W[0-4]" "/W4" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
    else()
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /W4")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /W4")
    endif()
elseif(CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_GNUCXX)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall")
    
    if(NOT NOPEDANTIC)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pedantic")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -pedantic")
    endif()
endif()

# Disable bogus MSVC warnings
if(MSVC)
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
endif()

# -fPIC thing
if(ENABLE_FPIC AND NOT WIN32 AND NOT VITA)
    message("== -fPIC enabled")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")
endif()

# Prevent shared libraries has "lib" prefix on Windows DLL files
if(WIN32)
    set(CMAKE_SHARED_LIBRARY_PREFIX "")
endif()
