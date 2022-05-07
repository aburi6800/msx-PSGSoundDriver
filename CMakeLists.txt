cmake_minimum_required(VERSION 3.0)

# target name "sample.rom"
project(sample.rom C ASM)

enable_language(ASM)

# for debug
# set(CMAKE_VERBOSE_MAKEFILE 1)

include(./cmake/macros.cmake)

header_directories(
    ./src/msx
    $ENV{Z88DK_HOME}/include
)

add_source_files(
    ./src/msx/sample.asm
    ./src/msx/psgdriver.asm
)

add_compile_flags(C
    +msx
    -vn
    -llib3d
    -lm
    -lndos
    -lmsxbios
    -m
    # https://github.com/z88dk/z88dk/wiki/Classic-allocation#automatic-heap-configuration
    -DAMALLOC
)

add_compile_flags(ASM
    +msx
)

add_compile_flags(LD
    -create-app
    -subtype=rom
    -m
)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ../dist)
add_executable(${PROJECT_NAME} ${SOURCE_FILES})
