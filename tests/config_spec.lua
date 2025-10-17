-- tests/config_spec.lua
-- Tests for configuration management

describe('config', function()
  local config

  -- Reset config before each test to avoid state pollution
  before_each(function()
    -- Clear the module cache to get a fresh instance
    package.loaded['mrreviewer.config'] = nil
    config = require('mrreviewer.core.config')
  end)

  describe('setup', function()
    it('initializes with default configuration', function()
      config.setup()
      local opts = config.get()

      assert.is_table(opts)
      assert.equals('float', opts.comment_display_mode)
      assert.is_table(opts.window)
      assert.equals(40, opts.window.comment_width)
      assert.is_true(opts.window.vertical_split)
    end)

    it('merges user options with defaults', function()
      config.setup({
        comment_display_mode = 'split',
        window = {
          comment_width = 50,
        },
      })

      local opts = config.get()
      assert.equals('split', opts.comment_display_mode)
      assert.equals(50, opts.window.comment_width)
      -- Should keep default for unspecified options
      assert.is_true(opts.window.vertical_split)
    end)

    it('performs deep merge for nested tables', function()
      config.setup({
        keymaps = {
          next_file = ']n',
          -- Other keymaps should remain as defaults
        },
      })

      local opts = config.get()
      assert.equals(']n', opts.keymaps.next_file)
      -- Defaults should be preserved
      assert.equals('[f', opts.keymaps.prev_file)
      assert.equals(']c', opts.keymaps.next_comment)
    end)

    it('overwrites nested values completely when specified', function()
      config.setup({
        glab = {
          path = '/custom/path/to/glab',
          timeout = 60000,
        },
      })

      local opts = config.get()
      assert.equals('/custom/path/to/glab', opts.glab.path)
      assert.equals(60000, opts.glab.timeout)
    end)

    it('handles empty user options', function()
      config.setup({})
      local opts = config.get()

      -- Should be identical to defaults
      assert.is_table(opts)
      assert.equals('float', opts.comment_display_mode)
    end)

    it('handles nil user options', function()
      config.setup(nil)
      local opts = config.get()

      -- Should be identical to defaults
      assert.is_table(opts)
      assert.equals('float', opts.comment_display_mode)
    end)

    it('allows multiple setup calls (reconfiguration)', function()
      config.setup({ comment_display_mode = 'split' })
      assert.equals('split', config.get().comment_display_mode)

      config.setup({ comment_display_mode = 'float' })
      assert.equals('float', config.get().comment_display_mode)
    end)
  end)

  describe('get', function()
    it('returns current configuration table', function()
      config.setup()
      local opts = config.get()

      assert.is_table(opts)
      assert.is_not_nil(opts.comment_display_mode)
      assert.is_table(opts.window)
      assert.is_table(opts.keymaps)
    end)

    it('returns configuration after custom setup', function()
      config.setup({
        comment_display_mode = 'virtual_text',
        window = { comment_width = 60 },
      })

      local opts = config.get()
      assert.equals('virtual_text', opts.comment_display_mode)
      assert.equals(60, opts.window.comment_width)
    end)
  end)

  describe('get_value', function()
    before_each(function()
      config.setup({
        comment_display_mode = 'split',
        window = {
          comment_width = 45,
          vertical_split = false,
        },
        glab = {
          timeout = 25000,
        },
      })
    end)

    it('retrieves top-level values', function()
      assert.equals('split', config.get_value('comment_display_mode'))
    end)

    it('retrieves nested values using dot notation', function()
      assert.equals(45, config.get_value('window.comment_width'))
      assert.is_false(config.get_value('window.vertical_split'))
      assert.equals(25000, config.get_value('glab.timeout'))
    end)

    it('retrieves deeply nested values', function()
      local value = config.get_value('keymaps.next_file')
      assert.equals(']f', value)
    end)

    it('returns nil for non-existent keys', function()
      assert.is_nil(config.get_value('nonexistent_key'))
      assert.is_nil(config.get_value('window.nonexistent'))
      assert.is_nil(config.get_value('deeply.nested.nonexistent'))
    end)

    it('returns nil when traversing through non-table values', function()
      -- comment_display_mode is a string, not a table
      assert.is_nil(config.get_value('comment_display_mode.something'))
    end)

    it('handles empty keys gracefully', function()
      -- Single empty key should return the whole options table
      local value = config.get_value('')
      assert.is_nil(value)
    end)

    it('retrieves table values', function()
      local window = config.get_value('window')
      assert.is_table(window)
      assert.equals(45, window.comment_width)
      assert.is_false(window.vertical_split)
    end)
  end)

  describe('configuration isolation', function()
    it('does not mutate defaults when modifying returned config', function()
      config.setup()
      local opts1 = config.get()
      opts1.comment_display_mode = 'MODIFIED'

      -- Setup again with defaults
      config.setup()
      local opts2 = config.get()

      -- Should be back to default, not MODIFIED
      assert.equals('float', opts2.comment_display_mode)
    end)

    it('deep copies nested tables', function()
      config.setup()
      local opts1 = config.get()
      opts1.window.comment_width = 999

      config.setup()
      local opts2 = config.get()

      -- Should be back to default
      assert.equals(40, opts2.window.comment_width)
    end)
  end)

  describe('default values', function()
    before_each(function()
      config.setup()
    end)

    it('has correct default comment_display_mode', function()
      assert.equals('float', config.get_value('comment_display_mode'))
    end)

    it('has correct default window settings', function()
      assert.equals(40, config.get_value('window.comment_width'))
      assert.is_true(config.get_value('window.vertical_split'))
      assert.is_true(config.get_value('window.sync_scroll'))
    end)

    it('has correct default keymaps', function()
      assert.equals(']f', config.get_value('keymaps.next_file'))
      assert.equals('[f', config.get_value('keymaps.prev_file'))
      assert.equals(']c', config.get_value('keymaps.next_comment'))
      assert.equals('[c', config.get_value('keymaps.prev_comment'))
      assert.equals('q', config.get_value('keymaps.close'))
      assert.equals('K', config.get_value('keymaps.show_comment'))
    end)

    it('has correct default glab settings', function()
      assert.equals('glab', config.get_value('glab.path'))
      assert.equals(30000, config.get_value('glab.timeout'))
    end)

    it('has correct default notification settings', function()
      assert.is_true(config.get_value('notifications.enabled'))
      assert.equals('info', config.get_value('notifications.level'))
    end)
  end)
end)
