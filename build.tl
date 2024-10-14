#!/usr/bin/env tl run

global type Printer = function(string)
local type Runner = function(printer:Printer, cmd:string, print_output?:boolean):(boolean,string,string)

local function exec_cmd_impl(printer:Printer, cmd:string, print_output?:boolean):(boolean,string,string)
    local read_and_remove_file = function(filename:string):string
        local output = ""
        local handle = io.open(filename, "r")
        if handle then
            output = handle:read("*all")
            handle:close()
        end
        os.remove(filename)
        return output
    end
    local out_file = "cmd_output.txt"
    local err_file = "cmd_error.txt"

    local full_cmd = cmd .. " > " .. out_file .. " 2> " .. err_file
    printer("#" .. cmd)
    local result = os.execute(full_cmd)

    local output = read_and_remove_file(out_file)
    local error_output = read_and_remove_file(err_file)

    if print_output then
        if output ~= "" then
            printer(output)
        end
        if error_output ~= "" then
            printer(error_output)
        end
    end

    return result == true, output, error_output
end

local function find_files(exec_cmd:Runner, printer:Printer, dir_path:string, extensions:{string}):{string}
    local end_with = function(str:string, suffix:string):boolean
        return str:sub(- #suffix) == suffix
    end

    local files:{string}={}

    local find_cmd = "find " .. dir_path .. " -type f"
    local result, file_list, errors = exec_cmd(print, find_cmd)

    if result ~= true then
        printer("Error finding files in directory: " .. errors)
        os.exit(1)
    end

    for file in file_list:gmatch("[^\r\n]+") do
        for _, ext in ipairs(extensions) do
            if end_with(file, ext) then
                table.insert(files, file)
            end
        end
    end

    return files
end

local function collect_include_dirs(files:{string}):{string}
    local include_dirs:{string} = {}
    local added_dirs:{string:boolean} = {}

    for _, file in ipairs(files) do
        local dir = file:match("(.*/)")
        if dir and not added_dirs[dir] then
            table.insert(include_dirs, dir)
            added_dirs[dir] = true
        end
    end

    return include_dirs
end


local record Options
    target:string
    sources:string
    compiler:string
    compiler_options:string
    linker:string
    linker_options:string
    sources_ext:{string}
    headers_ext:{string}
end


local function compile_source(exec_cmd:Runner, printer:Printer,  source_file:string, include_flags_str:string, options:Options):string
    local object_file =  source_file
    for _, ext in ipairs(options.sources_ext) do
       object_file = object_file:gsub(ext .. "$", ".o")
    end
    local compile_cmd = options.compiler .. " " .. options.compiler_options .. " "
        .. include_flags_str
        .. " -c " .. source_file
        .. " -o " .. object_file

    local result, _, errors = exec_cmd(print, compile_cmd, true)

    if result ~= true then
        printer("Error compiling " .. source_file .. ": " .. errors)
        os.exit(1)
    end

    return object_file
end

local function link_executable(exec_cmd:Runner, printer:Printer,  object_files:{string},options:Options)
    local link_cmd = options.linker .. " "
        .. options.linker_options .. " "
        .. table.concat(object_files, " ")
        .. " -o " .. options.target

    local result, _, errors = exec_cmd(print, link_cmd, true)

    if result ~= true then
        printer("Error linking executable: " .. errors)
        os.exit(1)
    end
end

local function clean_build(exec_cmd:Runner, printer:Printer,  options:Options)
    printer("Cleaning build...")
    local clean_cmd = "rm -f " .. options.sources .. "/*.o " .. options.target
    exec_cmd(printer, clean_cmd, true)
end

local function run_program(exec_cmd:Runner, printer:Printer,  options:Options)
    printer("Running " .. options.target .. "...")
    exec_cmd(print, "./" .. options.target .. " scene.xml", true)
end

local function build_project(exec_cmd:Runner, printer:Printer, options:Options)
    local source_files = find_files(exec_cmd, printer, options.sources, options.sources_ext)
    local header_files = find_files(exec_cmd, printer, options.sources, options.headers_ext)
    local include_dirs = collect_include_dirs(header_files)
    local include_flags:{string} = {}
    for _, idir in ipairs(include_dirs) do
        table.insert(include_flags, "-I" .. idir)
    end
    local include_flags_str = table.concat(include_flags, " ")

    local object_files:{string} = {}
    for _, source_file in ipairs(source_files) do
        local object_file = compile_source(exec_cmd, printer, source_file, include_flags_str, options)
        table.insert(object_files, object_file)
    end

    link_executable(exec_cmd, printer, object_files,options)
end

local function default_string(val:string, default:string):string
    if val == nil then return default end
    if val == "" then return default end
    return val
end

global function process_arguments(exec_cmd:Runner, printer:Printer, cli_arg:{string})
    local action = cli_arg[1]
    local options:Options = {
        target = default_string(cli_arg[2], "a.out"),
        sources = default_string(cli_arg[3], "src"),
        compiler = default_string(cli_arg[4], "clang++"),
        compiler_options = default_string(cli_arg[5], "-Wall -Wextra -std=c++11"),
        linker = default_string(cli_arg[6], "clang++"),
        linker_options = default_string(cli_arg[7], ""),
        sources_ext = {".c",".cpp"},
        headers_ext = {".h",".hpp"},
    }

    if action == "build" then
        build_project(exec_cmd, printer, options)
        printer("Build completed successfully.")
    elseif action == "clean" then
        clean_build(exec_cmd, printer, options)
        printer("Clean completed successfully.")
    elseif action == "run" then
        run_program(exec_cmd, printer, options)
    else
        print("Usage: ./build.tl [build|clean|run] [target]")
    end
end

global DontRun: boolean

if not DontRun then
    process_arguments(exec_cmd_impl, print, arg)
end
