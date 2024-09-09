local wezterm = require "wezterm"
local filesystem = {}

function basename(path)
    return string.gsub(path, "(.*/)(.*)", "%2")
end

function dirname(path)
    return string.gsub(path, "(.*/)(.*)", "%1")
end

function path_join(path_bits)
    return table.concat(path_bits, "/")
end

function get_cwd(pane)
    local cwd_uri = pane:get_current_working_dir()
    if cwd_uri then
        cwd = cwd_uri.file_path
        cwd = string.gsub(cwd, wezterm.home_dir, "~")
        return cwd
    end
    return nil
end

function file_exists(filename)
    local f = io.open(filename, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

function exists(file)
    local ok, err, code = os.rename(file, file)
    if not ok then
       if code == 13  or code == 1 then
          -- Permission denied, but it exists
          return true, nil
       end
    end
    return ok, err
 end

function is_dir(path)
    ok, err = exists(path.."/")
    if ok == true and err == nil then
        return true
    else
        return false
    end
end

filesystem.basename = basename
filesystem.dirname = dirname
filesystem.path_join = path_join
filesystem.get_cwd = get_cwd
filesystem.file_exists = file_exists
filesystem.exists = exists
filesystem.is_dir = is_dir

return filesystem
