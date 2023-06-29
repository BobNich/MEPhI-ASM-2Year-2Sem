if (ASSEMBLER)
    file(GLOB SOURCES asm/invert_image.s)
    set_source_files_properties(${SOURCES} PROPERTIES LANGUAGE ASM_NASM COMPILE_FLAGS "-g -F dwarf")
else ()
    file(GLOB SOURCES c/invert_image.c)
endif ()

add_library(lib STATIC ${SOURCES})

target_include_directories(lib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(lib m)