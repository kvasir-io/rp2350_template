cmake_minimum_required(VERSION 3.28)

if(NOT KVASIR_ROOT)
    if(DEFINED ENV{KVASIR_ROOT})
        set(KVASIR_ROOT $ENV{KVASIR_ROOT})
    else()
        include(FetchContent)
        FetchContent_Declare(
            Kvasir_SDK
            GIT_REPOSITORY https://github.com/kvasir-io/Kvasir_SDK.git
            GIT_TAG master)
        FetchContent_Declare(
            chip_rp2350
            GIT_REPOSITORY https://github.com/kvasir-io/chip_rp2350.git
            GIT_TAG master)
        FetchContent_Declare(
            kvasir_devices
            GIT_REPOSITORY https://github.com/kvasir-io/kvasir_devices.git
            GIT_TAG master)
        FetchContent_MakeAvailable(Kvasir_SDK chip_rp2350 kvasir_devices)
        set(KVASIR_ROOT ${kvasir_sdk_SOURCE_DIR})
        set(CHIP_ROOT ${chip_rp2350_SOURCE_DIR})
        set(KVASIR_DEVICES_ROOT ${kvasir_devices_SOURCE_DIR})
    endif()
endif()

include(${KVASIR_ROOT}/cmake/kvasir.cmake)

project(
    "rp2350_template"
    VERSION 0.1.0
    DESCRIPTION "RP2350 firmware template using Kvasir SDK")

include(${KVASIR_ROOT}/cmake/util.cmake)

kvasir_executable_variants("" SOURCES src/main.cpp LIBRARIES OPTIMIZATION size)
