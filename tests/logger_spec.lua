-- tests/logger_spec.lua
-- Tests for logging system module

describe('logger', function()
  local logger
  local test_log_path

  before_each(function()
    -- Fresh require to reset logger state
    package.loaded['mrreviewer.logger'] = nil
    logger = require('mrreviewer.core.logger')

    -- Use a test-specific log path
    test_log_path = vim.fn.tempname() .. '_mrreviewer_test.log'
    logger.setup({
      enabled = true,
      level = logger.levels.DEBUG,
      file_path = test_log_path,
      max_file_size = 1024, -- Small size for testing rotation
      max_backups = 2,
    })
  end)

  after_each(function()
    -- Clean up test log files
    if test_log_path then
      os.remove(test_log_path)
      for i = 1, 3 do
        os.remove(test_log_path .. '.' .. i)
      end
    end
  end)

  describe('configuration', function()
    it('should use default configuration when not setup', function()
      package.loaded['mrreviewer.logger'] = nil
      logger = require('mrreviewer.core.logger')

      assert.equals(true, logger.config.enabled)
      assert.equals(logger.levels.INFO, logger.config.level)
      assert.equals(10 * 1024 * 1024, logger.config.max_file_size)
      assert.equals(3, logger.config.max_backups)
    end)

    it('should accept custom configuration', function()
      logger.setup({
        enabled = false,
        level = logger.levels.ERROR,
        max_file_size = 5000,
        max_backups = 5,
      })

      assert.equals(false, logger.config.enabled)
      assert.equals(logger.levels.ERROR, logger.config.level)
      assert.equals(5000, logger.config.max_file_size)
      assert.equals(5, logger.config.max_backups)
    end)

    it('should accept string log levels', function()
      logger.setup({ level = 'WARN' })

      assert.equals(logger.levels.WARN, logger.config.level)
    end)

    it('should default to INFO for invalid log level strings', function()
      logger.setup({ level = 'INVALID' })

      assert.equals(logger.levels.INFO, logger.config.level)
    end)
  end)

  describe('log file creation', function()
    it('should create log file on first write', function()
      logger.info('test', 'Test message')

      assert.equals(1, vim.fn.filereadable(test_log_path))
    end)

    it('should create parent directory if needed', function()
      local nested_path = vim.fn.tempname() .. '/nested/dir/test.log'
      logger.setup({ file_path = nested_path })

      logger.info('test', 'Test message')

      assert.equals(1, vim.fn.filereadable(nested_path))

      -- Clean up
      os.remove(nested_path)
      vim.fn.delete(vim.fn.fnamemodify(nested_path, ':h'), 'rf')
    end)
  end)

  describe('log levels', function()
    it('should write DEBUG messages when level is DEBUG', function()
      logger.setup({ level = logger.levels.DEBUG, file_path = test_log_path })
      logger.debug('test', 'Debug message')

      local content = table.concat(vim.fn.readfile(test_log_path), '\n')
      assert.matches('DEBUG', content)
      assert.matches('Debug message', content)
    end)

    it('should write INFO messages when level is INFO', function()
      logger.setup({ level = logger.levels.INFO, file_path = test_log_path })
      logger.info('test', 'Info message')

      local content = table.concat(vim.fn.readfile(test_log_path), '\n')
      assert.matches('INFO', content)
      assert.matches('Info message', content)
    end)

    it('should write WARN messages when level is WARN', function()
      logger.setup({ level = logger.levels.WARN, file_path = test_log_path })
      logger.warn('test', 'Warn message')

      local content = table.concat(vim.fn.readfile(test_log_path), '\n')
      assert.matches('WARN', content)
      assert.matches('Warn message', content)
    end)

    it('should write ERROR messages when level is ERROR', function()
      logger.setup({ level = logger.levels.ERROR, file_path = test_log_path })
      logger.error('test', 'Error message')

      local content = table.concat(vim.fn.readfile(test_log_path), '\n')
      assert.matches('ERROR', content)
      assert.matches('Error message', content)
    end)

    it('should filter out messages below configured level', function()
      logger.setup({ level = logger.levels.WARN, file_path = test_log_path })

      logger.debug('test', 'Debug message')
      logger.info('test', 'Info message')
      logger.warn('test', 'Warn message')
      logger.error('test', 'Error message')

      local content = table.concat(vim.fn.readfile(test_log_path), '\n')

      assert.is_not.matches('Debug message', content)
      assert.is_not.matches('Info message', content)
      assert.matches('Warn message', content)
      assert.matches('Error message', content)
    end)
  end)

  describe('log format', function()
    it('should include timestamp in log entry', function()
      logger.info('test', 'Test message')

      local content = table.concat(vim.fn.readfile(test_log_path), '\n')
      assert.matches('%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d', content)
    end)

    it('should include log level in log entry', function()
      logger.info('test', 'Test message')

      local content = table.concat(vim.fn.readfile(test_log_path), '\n')
      assert.matches('INFO', content)
    end)

    it('should include module name in log entry', function()
      logger.info('test_module', 'Test message')

      local content = table.concat(vim.fn.readfile(test_log_path), '\n')
      assert.matches('test_module', content)
    end)

    it('should include context data when provided', function()
      logger.info('test', 'Test message', { key = 'value', number = 42 })

      local content = table.concat(vim.fn.readfile(test_log_path), '\n')
      assert.matches('Context:', content)
      assert.matches('key', content)
      assert.matches('value', content)
    end)
  end)

  describe('log_error', function()
    it('should log error object with type and message', function()
      local errors = require('mrreviewer.core.errors')
      local err = errors.git_error('Git operation failed', { command = 'git status' })

      logger.log_error('test', err)

      local content = table.concat(vim.fn.readfile(test_log_path), '\n')
      assert.matches('ERROR', content)
      assert.matches('Git operation failed', content)
      assert.matches('git status', content)
    end)

    it('should log non-error objects as strings', function()
      logger.log_error('test', 'Simple error string')

      local content = table.concat(vim.fn.readfile(test_log_path), '\n')
      assert.matches('ERROR', content)
      assert.matches('Simple error string', content)
    end)
  end)

  describe('disabled logging', function()
    it('should not write to file when disabled', function()
      logger.setup({ enabled = false, file_path = test_log_path })

      logger.info('test', 'Test message')

      assert.equals(0, vim.fn.filereadable(test_log_path))
    end)
  end)

  describe('log rotation', function()
    it('should rotate logs when file exceeds max size', function()
      logger.setup({
        file_path = test_log_path,
        max_file_size = 100, -- Very small for testing
        max_backups = 2,
      })

      -- Write enough data to trigger rotation
      for i = 1, 50 do
        logger.info('test', 'Message number ' .. i)
      end

      -- Check that backup files were created
      local has_backup = vim.fn.filereadable(test_log_path .. '.1') == 1

      assert.is_true(has_backup)
    end)

    it('should keep only max_backups old files', function()
      logger.setup({
        file_path = test_log_path,
        max_file_size = 50, -- Very small for testing
        max_backups = 2,
      })

      -- Write enough to create multiple rotations
      for i = 1, 100 do
        logger.info('test', 'Message ' .. i)
      end

      -- Should have current + 2 backups = 3 files max
      assert.equals(1, vim.fn.filereadable(test_log_path))
      -- At least one backup should exist
      local has_backups =
        vim.fn.filereadable(test_log_path .. '.1') == 1 or vim.fn.filereadable(test_log_path .. '.2') == 1

      assert.is_true(has_backups)

      -- Should not have more than max_backups
      assert.equals(0, vim.fn.filereadable(test_log_path .. '.3'))
    end)
  end)

  describe('get_recent_logs', function()
    it('should return empty array when log file does not exist', function()
      local logs = logger.get_recent_logs()

      assert.is_table(logs)
      assert.equals(0, #logs)
    end)

    it('should return recent log entries', function()
      logger.info('test', 'Message 1')
      logger.info('test', 'Message 2')
      logger.info('test', 'Message 3')

      local logs = logger.get_recent_logs()

      assert.is_table(logs)
      assert.is_true(#logs >= 3)
    end)

    it('should limit number of returned entries', function()
      for i = 1, 100 do
        logger.info('test', 'Message ' .. i)
      end

      local logs = logger.get_recent_logs(10)

      assert.equals(10, #logs)
    end)

    it('should return last N lines', function()
      logger.info('test', 'First message')
      logger.info('test', 'Second message')
      logger.info('test', 'Third message')

      local logs = logger.get_recent_logs(2)

      local content = table.concat(logs, '\n')
      assert.is_not.matches('First message', content)
      assert.matches('Second message', content)
      assert.matches('Third message', content)
    end)
  end)

  describe('clear_logs', function()
    it('should remove main log file', function()
      logger.info('test', 'Test message')
      assert.equals(1, vim.fn.filereadable(test_log_path))

      logger.clear_logs()

      assert.equals(0, vim.fn.filereadable(test_log_path))
    end)

    it('should remove backup log files', function()
      -- Create some backups
      logger.setup({
        file_path = test_log_path,
        max_file_size = 50,
        max_backups = 2,
      })

      for i = 1, 100 do
        logger.info('test', 'Message ' .. i)
      end

      logger.clear_logs()

      assert.equals(0, vim.fn.filereadable(test_log_path))
      assert.equals(0, vim.fn.filereadable(test_log_path .. '.1'))
      assert.equals(0, vim.fn.filereadable(test_log_path .. '.2'))
    end)
  end)

  describe('get_log_path', function()
    it('should return configured path', function()
      local path = logger.get_log_path()

      assert.equals(test_log_path, path)
    end)

    it('should return default path when not configured', function()
      package.loaded['mrreviewer.logger'] = nil
      logger = require('mrreviewer.core.logger')

      local path = logger.get_log_path()

      assert.is_not_nil(path)
      assert.matches('mrreviewer.log', path)
    end)
  end)
end)
