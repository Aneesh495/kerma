.PHONY: all clean test lint validate-shaders build-cpp

CXX ?= clang++
CXXFLAGS ?= -std=c++20 -O3 -Wall -Wextra -Wpedantic -Icpp/include
GLSLANG ?= glslangValidator
PYTHON ?= python3

all: validate-shaders build-cpp lint

validate-shaders:
	@echo "Validating GLSL compute, vertex, and fragment shaders with glslangValidator..."
	@$(PYTHON) tools/validate_shaders.py

build-cpp:
	@echo "Building C++ core fastpath..."
	@mkdir -p build
	@cd build && cmake .. && cmake --build . -j4

test: build-cpp
	@echo "Executing C++ test suite..."
	@./build/kerma_tests
	@echo "Executing Python test suite..."
	@PYTHONPATH=python $(PYTHON) -m unittest discover -s python/tests -v
	@echo "Executing typography check..."
	@$(PYTHON) tools/check_typography.py

lint:
	@$(PYTHON) tools/check_typography.py

clean:
	@rm -rf build bin *.spv
