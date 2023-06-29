include(FetchContent)

FetchContent_Declare(
    stb
    GIT_REPOSITORY https://github.com/nothings/stb
    GIT_TAG master
)

FetchContent_MakeAvailable(stb)

if (ASSEMBLER)
    file(GLOB SOURCES process_image.h process_image.c asm/invert_image.s)
    set_source_files_properties(${SOURCES} PROPERTIES LANGUAGE ASM_NASM COMPILE_FLAGS "-g -F dwarf")
else ()
    file(GLOB SOURCES process_image.h process_image.c c/invert_image.c)
endif ()

add_library(lib STATIC ${SOURCES})

target_include_directories(lib PUBLIC ${stb_SOURCE_DIR})
target_include_directories(lib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(lib m)