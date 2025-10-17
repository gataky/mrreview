-- Luacheck configuration for mrreviewer
-- Ensures code quality and catches potential issues

-- Use LuaJIT standard (Neovim's Lua version)
std = "luajit"

-- Global Neovim variables
globals = {
    "vim",  -- Main Neovim API
}

-- Read-only globals (can be read but not modified)
read_globals = {
    "vim",
}

-- Ignore some pedantic warnings
ignore = {
    "212",  -- Unused argument (common in callbacks)
    "213",  -- Unused loop variable (common in iteration)
}

-- Maximum line length (align with stylua config)
max_line_length = 100

-- Maximum cyclomatic complexity
max_cyclomatic_complexity = 15

-- Files and directories to exclude
exclude_files = {
    ".git/",
    "*.rockspec",
}

-- Test-specific configuration
files["tests/**/*.lua"] = {
    -- Allow test-specific globals
    globals = {
        "describe",
        "it",
        "before_each",
        "after_each",
        "assert",
        "pending",
        "setup",
        "teardown",
    },
    -- Ignore unused arguments in test functions
    ignore = {"212"},
}

-- Plugin entry point configuration
files["plugin/**/*.lua"] = {
    -- Plugin files can define global variables
    globals = {
        "vim",
    },
}
