local wezterm = require "wezterm"
local util = require "util"

github = {}

function branch_name(cwd)
    local return_code, command_output = util.execute_command(cwd, "git rev-parse --abbrev-ref HEAD")
    if return_code == 0 then
        return command_output
    else
        return nil
    end
end

function branch_commits_behind(cwd)
    local return_code, command_output = util.execute_command(cwd, "git rev-list --count HEAD..@{u}")
    if return_code == 0 then
        return tonumber(command_output)
    else
        return nil
    end
end

function branch_commits_ahead(cwd)
    local return_code, command_output = util.execute_command(cwd, "git rev-list --count @{u}..HEAD")
    if return_code == 0 then
        return tonumber(command_output)
    else
        return nil
    end
end

function foo(cwd)
    local return_code, command_output = util.execute_command(cwd, "git rev-list --left-right --count main...test-branch")
    if return_code == 0 then
        return tonumber(command_output)
    else
        return nil
    end
end

function branch_current_tag(cwd)
    local return_code, command_output = util.execute_command(cwd, "git describe --exact-match --tags $(git log -n1 --pretty='%h')")
    if return_code == 0 then
        return command_output
    else
        return nil
    end
end

function github.branch_info(cwd)
    local git_branch_name = branch_name(cwd)
    -- The following slow things down. Maybe there's a better way??
    -- local commits_behind = branch_commits_behind(cwd)
    -- local commits_ahead = branch_commits_ahead(cwd)
    -- local current_tag = branch_current_tag(cwd)
    return git_branch_name, commits_behind, commits_ahead, current_tag
end

-- Get the number of stars: https://api.github.com/repos/<user>/<repo>
-- Look in the JSON for "stargazers_count"

return github
