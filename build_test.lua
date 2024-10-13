DontRun = true

require "build"


local cmd_out = {}
local stdout = ""
local exec_called = {}

function mock_print(msg)
    stdout = stdout .. msg .. "\n"
end

function mock_exec_cmd(print, cmd, print_output)
    table.insert(exec_called, cmd)
    local out = cmd_out[#exec_called] or ""
    return true, out, ""
end

function setup(cmd_out_case)
    cmd_out = cmd_out_case
    stdout = ""
    exec_called = {}
end

function test(expected, out)
    if out ~= stdout then
        assert("stdout out missmatch want \n\t\t'" .. out
            .. "'\n\t but got \n\t\t'" .. stdout .. "'"
        )
    end
    if #expected ~= #exec_called then
        assert("call stack size expectd " .. #expected .. " but got " .. #exec_called)
    end
    for i = 1, #expected do
        if expected[i] ~= exec_called[i] then
            assert("for call [" .. i
                .. "] expectd \n\t\t'" .. expected[i]
                .. "'\n\tbut got\n\t\t'" .. exec_called[i] .. "'"
            )
        end
    end
end

local assert_scope = ""

function assert(msg)
    print("test " .. assert_scope .. " failed : \n\t" .. msg)
    os.exit(1)
end

function run(test_case)
    for k, v in pairs(test_case) do
        assert_scope = k
        setup(v.cmd_out)
        process_arguments(mock_exec_cmd, mock_print, v.arguments)
        test(v.exec_called, v.out)
    end
    print("Test successfully passed")
end

local test_case = {
    ["no source file"] = {
        arguments = { "build", "target_name" },
        cmd_out = {},
        exec_called = {
            "find src -type f",
            "find src -type f",
            "clang++  -o target_name",
        },
        out = "Build completed successfully.\n",
    },
    ["one cpp file"] = {
        arguments = { "build", "target_name" },
        cmd_out = {
            "src/main.cpp"
        },
        exec_called = {
            "find src -type f",
            "find src -type f",
            "clang++ -Wall -Wextra -std=c++11  -c src/main.cpp -o src/main.o",
            "clang++ src/main.o -o target_name",
        },
        out = "Build completed successfully.\n",
    },
    ["one cpp file with header lib"] = {
        arguments = { "build", "target_name" },
        cmd_out = {
            "src/main.cpp",
            "src/ext/stbimage.h",
        },
        exec_called = {
            "find src -type f",
            "find src -type f",
            "clang++ -Wall -Wextra -std=c++11 -Isrc/ext/ -c src/main.cpp -o src/main.o",
            "clang++ src/main.o -o target_name",
        },
        out = "Build completed successfully.\n",
    },
    ["two cpp file with header lib"] = {
        arguments = { "build", "target_name" },
        cmd_out = {
            "src/main.cpp\nsrc/internal/impl.cpp",
            "src/ext/stbimage.h\nsrc/internal/impl.hpp",
        },
        exec_called = {
            "find src -type f",
            "find src -type f",
            "clang++ -Wall -Wextra -std=c++11 -Isrc/ext/ -Isrc/internal/ -c src/main.cpp -o src/main.o",
            "clang++ -Wall -Wextra -std=c++11 -Isrc/ext/ -Isrc/internal/ -c src/internal/impl.cpp -o src/internal/impl.o",
            "clang++ src/main.o src/internal/impl.o -o target_name",
        },
        out = "Build completed successfully.\n",
    },
    ["one c file"] = {
        arguments = { "build", "target_name" },
        cmd_out = {
            "src/main.c"
        },
        exec_called = {
            "find src -type f",
            "find src -type f",
            "clang++ -Wall -Wextra -std=c++11  -c src/main.c -o src/main.o",
            "clang++ src/main.o -o target_name",
        },
        out = "Build completed successfully.\n",
    },
}

run(test_case)
