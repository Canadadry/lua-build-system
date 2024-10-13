DontRun = true

require "build"


local cmd_out = {}
local exec_called = {}

function mock_exec_cmd(cmd, print_output)
    table.insert(exec_called, cmd)
    local out = cmd_out[#exec_called] or ""
    return true, out, ""
end

function setup(cmd_out_case)
    cmd_out = cmd_out_case
    exec_called = {}
end

function test(expected)
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
        process_arguments(mock_exec_cmd, { "build", "target_name" })
        test(v.exec_called)
    end
    print("Test successfully passed")
end

local test_case = {
    ["no source file"] = {
        cmd_out = {},
        exec_called = {
            "find src -type f",
            "find src -type f",
            "clang++  -o target_name",
        },
    },
    ["one cpp file"] = {
        cmd_out = {
            "src/main.cpp"
        },
        exec_called = {
            "find src -type f",
            "find src -type f",
            "clang++ -Wall -Wextra -std=c++11  -c src/main.cpp -o src/main.o",
            "clang++ src/main.o -o target_name",
        },
    },
    ["one cpp file with header lib"] = {
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
    },
    ["two cpp file with header lib"] = {
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
    },
}

run(test_case)
