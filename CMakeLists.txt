cmake_minimum_required(VERSION 3.28)

# Kvasir_SDK: KVASIR_ROOT (variable or environment), else the checkout next to this repository, else fetched; the chip
# package and kvasir_devices the same way (kvasir_locate: Kvasir_SDK cmake/kvasir_locate.cmake)
if(NOT KVASIR_ROOT AND DEFINED ENV{KVASIR_ROOT})
    set(KVASIR_ROOT "$ENV{KVASIR_ROOT}")
endif()
if(NOT KVASIR_ROOT AND EXISTS "${CMAKE_CURRENT_LIST_DIR}/../Kvasir_SDK/cmake/kvasir_locate.cmake")
    get_filename_component(KVASIR_ROOT "${CMAKE_CURRENT_LIST_DIR}/../Kvasir_SDK" ABSOLUTE)
elseif(NOT KVASIR_ROOT)
    include(FetchContent)
    FetchContent_Declare(
        kvasir_sdk
        GIT_REPOSITORY https://github.com/kvasir-io/Kvasir_SDK.git
        GIT_TAG master
        GIT_SHALLOW TRUE
        GIT_SUBMODULES "" SOURCE_SUBDIR fetch-only)
    FetchContent_MakeAvailable(kvasir_sdk)
    set(KVASIR_ROOT "${kvasir_sdk_SOURCE_DIR}")
endif()
include("${KVASIR_ROOT}/cmake/kvasir_locate.cmake")
kvasir_locate(USE_ENVIRONMENT SDK_SUBMODULES ALL CHIP chip_rp2350 DEVICES)

include(${KVASIR_ROOT}/cmake/kvasir.cmake)

project(
    "rp2350_template"
    VERSION 0.1.0
    DESCRIPTION "RP2350 firmware template using Kvasir SDK")

include(${KVASIR_ROOT}/cmake/util.cmake)

# LOG_REFLECTED_STRUCTS OFF: no log line here formats a reflectable struct, so the log variants parse no aglio/glaze. A
# firmware that logs one says ON (it fails to compile with OFF: "undefined template remote_fmt::formatter<S>").
kvasir_executable_variants(
    ""
    SOURCES
    src/main.cpp
    LIBRARIES
    OPTIMIZATION
    size
    LOG_REFLECTED_STRUCTS
    OFF)
