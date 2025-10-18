-- lua/mrreviewer/integrations/mock_data.lua
-- Mock data for GitLab API responses when glab.mock_mode is enabled

local M = {}

--- Mock MR list response
M.mr_list = {
  {
    iid = 123,
    title = "feat: Add new authentication system",
    description = "This PR implements a new JWT-based authentication system with refresh tokens.\n\nChanges:\n- Add JWT token generation\n- Add refresh token logic\n- Add token validation middleware\n- Update user model with token fields",
    author = {
      username = "alice",
      name = "Alice Developer",
    },
    source_branch = "feature/jwt-auth",
    target_branch = "main",
    web_url = "https://gitlab.com/example/project/-/merge_requests/123",
    state = "opened",
    created_at = "2025-01-15T10:30:00Z",
    updated_at = "2025-01-17T14:20:00Z",
    labels = { "feature", "security" },
    upvotes = 3,
    downvotes = 0,
    user_notes_count = 5,
    has_conflicts = false,
  },
  {
    iid = 122,
    title = "fix: Resolve memory leak in websocket handler",
    description = "Fixes issue #456 where websocket connections were not being properly cleaned up.\n\n- Add connection cleanup on disconnect\n- Fix event listener removal\n- Add tests for connection lifecycle",
    author = {
      username = "bob",
      name = "Bob Engineer",
    },
    source_branch = "fix/websocket-leak",
    target_branch = "main",
    web_url = "https://gitlab.com/example/project/-/merge_requests/122",
    state = "opened",
    created_at = "2025-01-16T09:15:00Z",
    updated_at = "2025-01-17T11:45:00Z",
    labels = { "bug", "performance" },
    upvotes = 2,
    downvotes = 0,
    user_notes_count = 3,
    has_conflicts = false,
  },
}

--- Mock MR view response with comments
M.mr_view_with_comments = {
  iid = 123,
  title = "feat: Add new authentication system",
  description = "This PR implements a new JWT-based authentication system with refresh tokens.\n\nChanges:\n- Add JWT token generation\n- Add refresh token logic\n- Add token validation middleware\n- Update user model with token fields",
  author = {
    username = "alice",
    name = "Alice Developer",
    avatar_url = "https://gitlab.com/uploads/-/avatar.png",
  },
  source_branch = "feature/jwt-auth",
  target_branch = "main",
  web_url = "https://gitlab.com/example/project/-/merge_requests/123",
  state = "opened",
  created_at = "2025-01-15T10:30:00Z",
  updated_at = "2025-01-17T14:20:00Z",
  merged_at = nil,
  labels = { "feature", "security" },
  upvotes = 3,
  downvotes = 0,
  user_notes_count = 5,
  has_conflicts = false,
  sha = "abc123def456",
  diff_refs = {
    base_sha = "base123",
    head_sha = "head456",
    start_sha = "start789",
  },
  changes = {
    {
      old_path = "src/auth/token.lua",
      new_path = "src/auth/token.lua",
      path = "src/auth/token.lua",
      new_file = true,
      deleted_file = false,
      renamed_file = false,
    },
    {
      old_path = "src/auth/middleware.lua",
      new_path = "src/auth/middleware.lua",
      path = "src/auth/middleware.lua",
      new_file = false,
      deleted_file = false,
      renamed_file = false,
    },
  },
  notes = {
    {
      id = 1001,
      type = "DiffNote",
      body = "Great implementation! Just a small suggestion: consider adding rate limiting to the token endpoint.",
      author = {
        username = "charlie",
        name = "Charlie Reviewer",
      },
      created_at = "2025-01-16T11:20:00Z",
      updated_at = "2025-01-16T11:20:00Z",
      system = false,
      resolvable = true,
      resolved = false,
      discussion_id = "disc_xyz789",
      position = {
        base_sha = "base123",
        start_sha = "start789",
        head_sha = "head456",
        position_type = "text",
        old_path = "src/auth/token.lua",
        new_path = "src/auth/token.lua",
        old_line = nil,
        new_line = 45,
      },
    },
    {
      id = 1008,
      type = "DiffNote",
      body = "Thanks for the feedback! I'll add rate limiting in the next iteration. Should we limit by IP or by user?",
      author = {
        username = "alice",
        name = "Alice Developer",
      },
      created_at = "2025-01-16T13:45:00Z",
      updated_at = "2025-01-16T13:45:00Z",
      system = false,
      resolvable = true,
      resolved = false,
      discussion_id = "disc_xyz789", -- Reply to comment 1001
      position = {
        base_sha = "base123",
        start_sha = "start789",
        head_sha = "head456",
        position_type = "text",
        old_path = "src/auth/token.lua",
        new_path = "src/auth/token.lua",
        old_line = nil,
        new_line = 45,
      },
    },
    {
      id = 1009,
      type = "DiffNote",
      body = "I'd suggest by user first, then add IP-based limiting as a fallback for unauthenticated requests.",
      author = {
        username = "charlie",
        name = "Charlie Reviewer",
      },
      created_at = "2025-01-16T14:00:00Z",
      updated_at = "2025-01-16T14:00:00Z",
      system = false,
      resolvable = true,
      resolved = false,
      discussion_id = "disc_xyz789", -- Reply in same thread
      position = {
        base_sha = "base123",
        start_sha = "start789",
        head_sha = "head456",
        position_type = "text",
        old_path = "src/auth/token.lua",
        new_path = "src/auth/token.lua",
        old_line = nil,
        new_line = 45,
      },
    },
    {
      id = 1002,
      type = "DiffNote",
      body = "Should we add error handling here for invalid tokens?",
      author = {
        username = "dave",
        name = "Dave Security",
      },
      created_at = "2025-01-16T14:30:00Z",
      updated_at = "2025-01-16T14:30:00Z",
      system = false,
      resolvable = true,
      resolved = false,
      discussion_id = "disc_abc123",
      position = {
        base_sha = "base123",
        start_sha = "start789",
        head_sha = "head456",
        position_type = "text",
        old_path = "src/auth/middleware.lua",
        new_path = "src/auth/middleware.lua",
        old_line = nil,
        new_line = 23,
      },
    },
    {
      id = 1003,
      type = "DiffNote",
      body = "Good catch! Fixed in latest commit.",
      author = {
        username = "alice",
        name = "Alice Developer",
      },
      created_at = "2025-01-17T09:15:00Z",
      updated_at = "2025-01-17T09:15:00Z",
      system = false,
      resolvable = true,
      resolved = true,
      discussion_id = "disc_abc123", -- Same thread as 1002
      position = {
        base_sha = "base123",
        start_sha = "start789",
        head_sha = "head456",
        position_type = "text",
        old_path = "src/auth/middleware.lua",
        new_path = "src/auth/middleware.lua",
        old_line = nil,
        new_line = 23,
      },
    },
    {
      id = 1004,
      type = "DiscussionNote",
      body = "Approved! Great work on this feature. The test coverage is excellent.",
      author = {
        username = "eve",
        name = "Eve Manager",
      },
      created_at = "2025-01-17T14:00:00Z",
      updated_at = "2025-01-17T14:00:00Z",
      system = false,
      resolvable = false,
      resolved = false,
    },
    {
      id = 1005,
      type = "DiffNote",
      body = "Consider using a constant for the token expiry time instead of a magic number.",
      author = {
        username = "frank",
        name = "Frank Code Quality",
      },
      created_at = "2025-01-17T14:10:00Z",
      updated_at = "2025-01-17T14:10:00Z",
      system = false,
      resolvable = true,
      resolved = false,
      position = {
        base_sha = "base123",
        start_sha = "start789",
        head_sha = "head456",
        position_type = "text",
        old_path = "src/auth/token.lua",
        new_path = "src/auth/token.lua",
        old_line = nil,
        new_line = 12,
        new_line_end = 18, -- Multi-line comment spanning lines 12-18
      },
    },
    {
      id = 1006,
      type = "DiffNote",
      body = "This entire validation block looks good, but we should add a check for token expiration before decoding to avoid unnecessary processing.",
      author = {
        username = "grace",
        name = "Grace Performance",
      },
      created_at = "2025-01-17T15:00:00Z",
      updated_at = "2025-01-17T15:00:00Z",
      system = false,
      resolvable = true,
      resolved = false,
      position = {
        base_sha = "base123",
        start_sha = "start789",
        head_sha = "head456",
        position_type = "text",
        old_path = "src/auth/token.lua",
        new_path = "src/auth/token.lua",
        old_line = nil,
        new_line = 35,
        new_line_end = 46, -- Multi-line comment spanning lines 35-46
      },
    },
    {
      id = 1007,
      type = "DiffNote",
      body = "The entire authentication flow here needs better error messages. Users should know why authentication failed (missing token vs invalid token vs expired token).",
      author = {
        username = "henry",
        name = "Henry UX",
      },
      created_at = "2025-01-17T15:30:00Z",
      updated_at = "2025-01-17T15:30:00Z",
      system = false,
      resolvable = true,
      resolved = false,
      position = {
        base_sha = "base123",
        start_sha = "start789",
        head_sha = "head456",
        position_type = "text",
        old_path = "src/auth/middleware.lua",
        new_path = "src/auth/middleware.lua",
        old_line = nil,
        new_line = 14,
        new_line_end = 26, -- Multi-line comment spanning lines 14-26
      },
    },
  },
}

--- Mock MR diff response
M.mr_diff = [[
diff --git a/src/auth/token.lua b/src/auth/token.lua
new file mode 100644
index 0000000..abc1234
--- /dev/null
+++ b/src/auth/token.lua
@@ -0,0 +1,58 @@
+-- src/auth/token.lua
+-- JWT token generation and validation
+
+local jwt = require('lua-jwt')
+local config = require('config')
+
+local M = {}
+
+--- Generate a JWT access token
+--- @param user_id number User ID
+--- @return string JWT token
+function M.generate_access_token(user_id)
+  local expiry = os.time() + 3600 -- 1 hour
+  return jwt.encode({
+    user_id = user_id,
+    exp = expiry,
+    type = 'access',
+  }, config.jwt_secret)
+end
+
+--- Generate a refresh token
+--- @param user_id number User ID
+--- @return string Refresh token
+function M.generate_refresh_token(user_id)
+  local expiry = os.time() + (30 * 24 * 3600) -- 30 days
+  return jwt.encode({
+    user_id = user_id,
+    exp = expiry,
+    type = 'refresh',
+  }, config.jwt_secret)
+end
+
+--- Validate a JWT token
+--- @param token string JWT token
+--- @return table|nil Decoded payload or nil if invalid
+function M.validate_token(token)
+  local ok, decoded = pcall(jwt.decode, token, config.jwt_secret)
+  if not ok then
+    return nil
+  end
+
+  -- Check expiry
+  if decoded.exp < os.time() then
+    return nil
+  end
+
+  return decoded
+end
+
+--- Refresh an access token using a refresh token
+--- @param refresh_token string Refresh token
+--- @return string|nil New access token or nil if invalid
+function M.refresh_access_token(refresh_token)
+  local decoded = M.validate_token(refresh_token)
+  if not decoded or decoded.type ~= 'refresh' then
+    return nil
+  end
+  return M.generate_access_token(decoded.user_id)
+end
+
+return M
diff --git a/src/auth/middleware.lua b/src/auth/middleware.lua
index def5678..ghi9012
--- a/src/auth/middleware.lua
+++ b/src/auth/middleware.lua
@@ -10,6 +10,20 @@ local M = {}
 --- @param next function Next middleware function
 function M.authenticate(req, res, next)
   local token = req.headers['Authorization']
+
+  if not token then
+    return res.status(401).json({ error = 'No token provided' })
+  end
+
+  -- Remove 'Bearer ' prefix
+  token = token:gsub('^Bearer%s+', '')
+
+  local decoded = token_module.validate_token(token)
+  if not decoded then
+    return res.status(401).json({ error = 'Invalid or expired token' })
+  end
+
+  req.user_id = decoded.user_id
   next()
 end

]]

--- Get mock response for a glab command
--- @param args table Command arguments
--- @return number, string, string exit_code, stdout, stderr
function M.get_mock_response(args)
  local cmd = table.concat(args, ' ')

  -- MR diff command (check first since it's simpler)
  if args[1] == 'mr' and args[2] == 'diff' then
    return 0, M.mr_diff, ''
  end

  -- MR list command
  if args[1] == 'mr' and args[2] == 'list' then
    return 0, vim.json.encode(M.mr_list), ''
  end

  -- MR view with comments
  if args[1] == 'mr' and args[2] == 'view' and vim.tbl_contains(args, '--comments') then
    return 0, vim.json.encode(M.mr_view_with_comments), ''
  end

  -- MR view without comments
  if args[1] == 'mr' and args[2] == 'view' then
    local view_without_comments = vim.deepcopy(M.mr_view_with_comments)
    view_without_comments.notes = nil
    return 0, vim.json.encode(view_without_comments), ''
  end

  -- Unknown command
  return 1, '', 'Mock command not recognized: ' .. cmd
end

--- Mock file content for git show commands
M.mock_files = {
  ["src/auth/token.lua"] = {
    base_sha = {}, -- New file, doesn't exist in base
    head_sha = {
      "-- src/auth/token.lua",
      "-- JWT token generation and validation",
      "",
      "local jwt = require('lua-jwt')",
      "local config = require('config')",
      "",
      "local M = {}",
      "",
      "--- Generate a JWT access token",
      "--- @param user_id number User ID",
      "--- @return string JWT token",
      "function M.generate_access_token(user_id)",
      "  local expiry = os.time() + 3600 -- 1 hour",
      "  return jwt.encode({",
      "    user_id = user_id,",
      "    exp = expiry,",
      "    type = 'access',",
      "  }, config.jwt_secret)",
      "end",
      "",
      "--- Generate a refresh token",
      "--- @param user_id number User ID",
      "--- @return string Refresh token",
      "function M.generate_refresh_token(user_id)",
      "  local expiry = os.time() + (30 * 24 * 3600) -- 30 days",
      "  return jwt.encode({",
      "    user_id = user_id,",
      "    exp = expiry,",
      "    type = 'refresh',",
      "  }, config.jwt_secret)",
      "end",
      "",
      "--- Validate a JWT token",
      "--- @param token string JWT token",
      "--- @return table|nil Decoded payload or nil if invalid",
      "function M.validate_token(token)",
      "  local ok, decoded = pcall(jwt.decode, token, config.jwt_secret)",
      "  if not ok then",
      "    return nil",
      "  end",
      "",
      "  -- Check expiry",
      "  if decoded.exp < os.time() then",
      "    return nil",
      "  end",
      "",
      "  return decoded",
      "end",
      "",
      "--- Refresh an access token using a refresh token",
      "--- @param refresh_token string Refresh token",
      "--- @return string|nil New access token or nil if invalid",
      "function M.refresh_access_token(refresh_token)",
      "  local decoded = M.validate_token(refresh_token)",
      "  if not decoded or decoded.type ~= 'refresh' then",
      "    return nil",
      "  end",
      "  return M.generate_access_token(decoded.user_id)",
      "end",
      "",
      "return M",
    },
  },
  ["src/auth/middleware.lua"] = {
    base_sha = {
      "-- src/auth/middleware.lua",
      "-- Authentication middleware",
      "",
      "local M = {}",
      "",
      "--- Authenticate incoming requests",
      "--- @param req table Request object",
      "--- @param res table Response object",
      "--- @param next function Next middleware function",
      "function M.authenticate(req, res, next)",
      "  local token = req.headers['Authorization']",
      "  next()",
      "end",
      "",
      "return M",
    },
    head_sha = {
      "-- src/auth/middleware.lua",
      "-- Authentication middleware",
      "",
      "local token_module = require('auth.token')",
      "",
      "local M = {}",
      "",
      "--- Authenticate incoming requests",
      "--- @param req table Request object",
      "--- @param res table Response object",
      "--- @param next function Next middleware function",
      "function M.authenticate(req, res, next)",
      "  local token = req.headers['Authorization']",
      "",
      "  if not token then",
      "    return res.status(401).json({ error = 'No token provided' })",
      "  end",
      "",
      "  -- Remove 'Bearer ' prefix",
      "  token = token:gsub('^Bearer%s+', '')",
      "",
      "  local decoded = token_module.validate_token(token)",
      "  if not decoded then",
      "    return res.status(401).json({ error = 'Invalid or expired token' })",
      "  end",
      "",
      "  req.user_id = decoded.user_id",
      "  next()",
      "end",
      "",
      "return M",
    },
  },
}

--- Get mock file content for git show command
--- @param file_path string File path
--- @param ref string Git ref (e.g., 'base_sha', 'head_sha', or actual sha)
--- @return table|nil Lines of file content or nil
function M.get_mock_file_content(file_path, ref)
  local file_data = M.mock_files[file_path]
  if not file_data then
    return nil
  end

  -- Map actual SHAs to base/head
  if ref == "base123" then
    ref = "base_sha"
  elseif ref == "head456" then
    ref = "head_sha"
  end

  return file_data[ref]
end

return M
