global DontRun:boolean = true

require "build"


local cmd_out:{string} = {}
local stdout = ""
local exec_called:{string} = {}

local function mock_print(msg:string):string
    stdout = stdout .. msg .. "\n"
end

local function mock_exec_cmd(_:Printer, cmd:string, _?:boolean):(boolean,string,string)
    table.insert(exec_called, cmd)
    local out = cmd_out[#exec_called] or ""
    return true, out, ""
end

local failed_scope = ""

local function failed(msg:string)
    print("test " .. failed_scope .. " failed : \n\t" .. msg)
    os.exit(1)
end

local function setup(cmd_out_case:{string})
    cmd_out = cmd_out_case
    stdout = ""
    exec_called = {}
end

local function test(expected:{string}, out:string)
    if out ~= stdout then
        failed("stdout out missmatch want \n\t\t'" .. out
            .. "'\n\t but got \n\t\t'" .. stdout .. "'"
        )
    end
    if #expected ~= #exec_called then
        failed("call stack size expectd " .. #expected .. " but got " .. #exec_called)
    end
    for i = 1, #expected do
        if expected[i] ~= exec_called[i] then
            failed("for call [" .. i
                .. "] expectd \n\t\t'" .. expected[i]
                .. "'\n\tbut got\n\t\t'" .. exec_called[i] .. "'"
            )
        end
    end
end

local record TestCase
    arguments:{string}
    cmd_out:{string}
    exec_called:{string}
    out:string
end

local function run(test_case:{string:TestCase})
    for k, v in pairs(test_case) do
        failed_scope = k
        setup(v.cmd_out)
        process_arguments(mock_exec_cmd, mock_print, v.arguments)
        test(v.exec_called, v.out)
    end
    print("Test successfully passed")
end

local test_case:{string:TestCase} = {
    ["no source file"] = {
        arguments = { "build", "target_name" },
        cmd_out = {},
        exec_called = {
            "find src -type f",
            "find src -type f",
            "clang++   -o target_name",
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
            "clang++  src/main.o -o target_name",
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
            "clang++  src/main.o -o target_name",
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
            "clang++  src/main.o src/internal/impl.o -o target_name",
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
            "clang++  src/main.o -o target_name",
        },
        out = "Build completed successfully.\n",
    },
    ["change compiler"] = {
        arguments = { "build", "target_name", "", "gcc","","gcc" },
        cmd_out = {
            "src/main.c"
        },
        exec_called = {
            "find src -type f",
            "find src -type f",
            "gcc -Wall -Wextra -std=c++11  -c src/main.c -o src/main.o",
            "gcc  src/main.o -o target_name",
        },
        out = "Build completed successfully.\n",
    },
    ["change compiler option"] = {
        arguments = { "build", "target_name", "", "gcc", "-pedantic", "gcc" },
        cmd_out = {
            "src/main.c"
        },
        exec_called = {
            "find src -type f",
            "find src -type f",
            "gcc -pedantic  -c src/main.c -o src/main.o",
            "gcc  src/main.o -o target_name",
        },
        out = "Build completed successfully.\n",
    },
    ["change linker option"] = {
        arguments = { "build", "target_name", "", "gcc", "-pedantic", "gcc","-O2" },
        cmd_out = {
            "src/main.c"
        },
        exec_called = {
            "find src -type f",
            "find src -type f",
            "gcc -pedantic  -c src/main.c -o src/main.o",
            "gcc -O2 src/main.o -o target_name",
        },
        out = "Build completed successfully.\n",
    },
    ["change linker option without changing compiler and compilr_options"] = {
        arguments = { "build", "target_name", "", "", "","", "-O2" },
        cmd_out = {
            "src/main.c"
        },
        exec_called = {
            "find src -type f",
            "find src -type f",
            "clang++ -Wall -Wextra -std=c++11  -c src/main.c -o src/main.o",
            "clang++ -O2 src/main.o -o target_name",
        },
        out = "Build completed successfully.\n",
    },

    ["change the source folder"] = {
        arguments = { "build", "target_name", "sources" },
        cmd_out = {
            "sources/main.c"
        },
        exec_called = {
            "find sources -type f",
            "find sources -type f",
            "clang++ -Wall -Wextra -std=c++11  -c sources/main.c -o sources/main.o",
            "clang++  sources/main.o -o target_name",
        },
        out = "Build completed successfully.\n",
    },
}

run(test_case)
