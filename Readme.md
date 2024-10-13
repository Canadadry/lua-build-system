# Lua Build System

This project is a Lua-based build system designed to compile C++ projects. It can handle building, cleaning, and running a program by using clang++. It supports multi-action CLI commands and includes test cases to verify the correctness of the build process. For an easier developpment [Teal](https://github.com/teal-language/tl) is used in place of lua.

## Features

 - Compile C++ projects: Automatically compiles .cpp files and links them into an executable.
 - Header file management: Collects include directories from .h and .hpp files found in the project.
 - Clean and run support: Allows for cleaning up build artifacts and running the resulting executable.
 - Testing: The project includes test cases that mock the build process to verify correct behavior.

## Prerequisites

Make sure you have the following installed on your system: `lua`,`teal`

````bash
luarocks install tl
tl run build_test.tl
tl gen build.tl
```

## Exected Project Structure

```
build-system/
│
├── build.lua              # Main build script
└── src/                   # Placeholder for your project source files
    ├── main.cpp           # Example C++ source file
    └── ...                # Other source and header files
```

## Build Script Usage

The build system allows for three main actions: build, clean, and run. These actions are controlled via command-line arguments when running the build.lua script.

### 1. Build the Project

To compile the project and generate the executable:

```bash
lua build.lua build <target_name> <compiler> <compiler_options> <linker_options>
```

With :
 - `<target_name>` is the name of the final executable you want to create. Default `a.out`
 - `<source>` is the directory where source file a stored. Default `src`
 - `<compiler>` is binary name of compiler. Default `clang++`
 - `<compiler_options>` are the options passed to the compiler . Default `-Wall -Wextra -std=c++11`
 - `<linker_options>` are the options passed to the link . Default ` `

The build process will:

    Search for .cpp/.c source files in the src/ directory.
    Compile each .c/.cpp file into an object file.
    Link the object files into the final executable.


### 2. Clean the Project

To remove all object files and the compiled executable:

```bash
lua build.lua clean
```

This will delete all .o files in the src/ directory and the generated executable.

### 3. Run the Program

To run the compiled executable:

```bash
lua build.lua run <target_name>
```

Where <target_name> is the name of the executable you want to run (the same name you used during the build).

## Running Tests

The project includes a tests.lua script that contains unit tests for the build system. These tests mock the execution of clang++ and validate that the correct commands are being called in different scenarios (e.g., no source files, one source file, with headers, etc.).
Running Tests

To run the test suite:

```bash
lua tests.lua
```

## License

This project is licensed under the MIT License.
