cmake_minimum_required(VERSION 3.20)
project(kerma VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Optimization and warning flags
if(MSVC)
    add_compile_options(/W4 /O2)
else()
    add_compile_options(-Wall -Wextra -Wpedantic -O3)
endif()

# Include directories
include_directories(cpp/include)

# Fastpath library
add_library(kerma_core
    cpp/src/phantom.cpp
    cpp/src/beam_geometry.cpp
    cpp/src/analytical_dose.cpp
    cpp/src/gamma_evaluation.cpp
    cpp/src/dvh_analyzer.cpp
)

# CLI executable
add_executable(kerma_cli
    cpp/src/main.cpp
)
target_link_libraries(kerma_cli PRIVATE kerma_core)

# Test executable
enable_testing()
add_executable(kerma_tests
    cpp/tests/test_phantom.cpp
    cpp/tests/test_geometry.cpp
    cpp/tests/test_analytical_dose.cpp
    cpp/tests/test_gamma.cpp
)
target_link_libraries(kerma_tests PRIVATE kerma_core)
add_test(NAME AllTests COMMAND kerma_tests)
