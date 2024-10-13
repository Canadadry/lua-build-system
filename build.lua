function exec_cmd_impl(cmd, print_output)
    local read_and_remove_file = function(filename)
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
    print("#" .. cmd)
    local result = os.execute(full_cmd)

    local output = read_and_remove_file(out_file)
    local error_output = read_and_remove_file(err_file)

    if print_output then
        if output ~= "" then
            print(output)
        end
        if error_output ~= "" then
            print(error_output)
        end
    end

    return result == true, output, error_output
end

function find_files(exec_cmd, dir_path, extensions)
    local files = {}

    local find_cmd = "find " .. dir_path .. " -type f"
    local result, file_list, errors = exec_cmd(find_cmd)

    if result ~= true then
        print("Error finding files in directory: " .. errors)
        os.exit(1)
    end

    for file in file_list:gmatch("[^\r\n]+") do
        local ext = file:match("^.+(%..+)$")
        if ext and extensions[ext] then
            table.insert(files, file)
        end
    end

    return files
end

function collect_include_dirs(files)
    local include_dirs = {}
    local added_dirs = {}

    for _, file in ipairs(files) do
        local dir = file:match("(.*/)")
        if dir and not added_dirs[dir] then
            table.insert(include_dirs, dir)
            added_dirs[dir] = true
        end
    end

    return include_dirs
end

function compile_source(exec_cmd, source_file, include_flags_str)
    local object_file = source_file:gsub(".cpp$", ".o")
    local compile_cmd = "clang++ -Wall -Wextra -std=c++11 "
        .. include_flags_str
        .. " -c " .. source_file
        .. " -o " .. object_file

    local result, _, errors = exec_cmd(compile_cmd, true)

    if result ~= true then
        print("Error compiling " .. source_file .. ": " .. errors)
        os.exit(1)
    end

    return object_file
end

function link_executable(exec_cmd, object_files, target)
    local link_cmd = "clang++ " .. table.concat(object_files, " ") .. " -o " .. target

    local result, _, errors = exec_cmd(link_cmd, true)

    if result ~= true then
        print("Error linking executable: " .. errors)
        os.exit(1)
    end

    print("Build completed successfully.")
end

function clean_build(exec_cmd, target)
    print("Cleaning build...")
    local clean_cmd = "rm -f src/*.o " .. target
    exec_cmd(clean_cmd, true)
    print("Clean completed successfully.")
end

function run_program(exec_cmd, target)
    print("Running " .. target .. "...")
    exec_cmd("./" .. target .. " scene.xml", true)
end

function build_project(exec_cmd, target)
    local source_exts = { [".cpp"] = true }
    local header_exts = { [".h"] = true, [".hpp"] = true }

    local source_files = find_files(exec_cmd, "src", source_exts)
    local header_files = find_files(exec_cmd, "src", header_exts)
    local include_dirs = collect_include_dirs(header_files)
    local include_flags = {}
    for _, idir in ipairs(include_dirs) do
        table.insert(include_flags, "-I" .. idir)
    end
    local include_flags_str = table.concat(include_flags, " ")

    local object_files = {}
    for _, source_file in ipairs(source_files) do
        local object_file = compile_source(exec_cmd, source_file, include_flags_str)
        table.insert(object_files, object_file)
    end

    link_executable(exec_cmd, object_files, target)
end

function process_arguments(exec_cmd, cli_arg)
    local action = cli_arg[1]
    local target = cli_arg[2] or "a.aout"

    if action == "build" then
        build_project(exec_cmd, target)
    elseif action == "clean" then
        clean_build(exec_cmd, target)
    elseif action == "run" then
        run_program(exec_cmd, target)
    else
        print("Usage: lua build.lua [build|clean|run] [target]")
    end
end

if not _G.DontRun then
    process_arguments(exec_cmd_impl, arg)
end
