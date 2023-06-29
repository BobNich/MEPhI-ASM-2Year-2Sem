cmake_minimum_required(VERSION 3.20)

project(lab5 VERSION 1.0.0 LANGUAGES C ASM_NASM)

set(EXECUTABLE lab.out)

include(FetchContent)

FetchContent_Declare(
    stb
    GIT_REPOSITORY https://github.com/nothings/stb
    GIT_TAG master
)

FetchContent_MakeAvailable(stb)

option(ASSEMBLER "Use assembly implementation" ON)

file(COPY images DESTINATION ${CMAKE_CURRENT_BINARY_DIR})

add_executable(${EXECUTABLE} main.c)

if (ASSEMBLER)
    message("Using ASM implementation")
else ()
    set(OPTIMIZATION "0" CACHE STRING "Optimization level")
    add_compile_options(-g0 -O${OPTIMIZATION})
    message("Using C implementation with optimization: ${OPTIMIZATION}")
endif ()

add_subdirectory(lib)

target_include_directories(${EXECUTABLE} PUBLIC lib)

target_include_directories(${EXECUTABLE} PUBLIC ${stb_SOURCE_DIR})

target_link_libraries(${EXECUTABLE} lib)