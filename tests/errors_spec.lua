-- tests/errors_spec.lua
-- Tests for error handling module

describe('errors', function()
  local errors

  before_each(function()
    errors = require('mrreviewer.errors')
  end)

  describe('ErrorType enum', function()
    it('should define all error types', function()
      assert.is_not_nil(errors.ErrorType.GIT)
      assert.is_not_nil(errors.ErrorType.NETWORK)
      assert.is_not_nil(errors.ErrorType.PARSE)
      assert.is_not_nil(errors.ErrorType.CONFIG)
      assert.is_not_nil(errors.ErrorType.VALIDATION)
      assert.is_not_nil(errors.ErrorType.IO)
      assert.is_not_nil(errors.ErrorType.UNKNOWN)
    end)
  end)

  describe('new', function()
    it('should create error object with type and message', function()
      local err = errors.new(errors.ErrorType.GIT, 'git command failed')

      assert.equals(errors.ErrorType.GIT, err.type)
      assert.equals('git command failed', err.message)
      assert.is_table(err.context)
      assert.is_number(err.timestamp)
      assert.is_string(err.traceback)
    end)

    it('should use UNKNOWN type if type not provided', function()
      local err = errors.new(nil, 'some error')

      assert.equals(errors.ErrorType.UNKNOWN, err.type)
    end)

    it('should use default message if message not provided', function()
      local err = errors.new(errors.ErrorType.GIT, nil)

      assert.equals('An unknown error occurred', err.message)
    end)

    it('should include context if provided', function()
      local err = errors.new(errors.ErrorType.GIT, 'error', { command = 'git status' })

      assert.equals('git status', err.context.command)
    end)
  end)

  describe('error type constructors', function()
    it('should create GitError', function()
      local err = errors.git_error('git failed')

      assert.equals(errors.ErrorType.GIT, err.type)
      assert.equals('git failed', err.message)
    end)

    it('should create NetworkError', function()
      local err = errors.network_error('network failed')

      assert.equals(errors.ErrorType.NETWORK, err.type)
      assert.equals('network failed', err.message)
    end)

    it('should create ParseError', function()
      local err = errors.parse_error('parse failed')

      assert.equals(errors.ErrorType.PARSE, err.type)
      assert.equals('parse failed', err.message)
    end)

    it('should create ConfigError', function()
      local err = errors.config_error('config invalid')

      assert.equals(errors.ErrorType.CONFIG, err.type)
      assert.equals('config invalid', err.message)
    end)

    it('should create ValidationError', function()
      local err = errors.validation_error('validation failed')

      assert.equals(errors.ErrorType.VALIDATION, err.type)
      assert.equals('validation failed', err.message)
    end)

    it('should create IOError', function()
      local err = errors.io_error('io failed')

      assert.equals(errors.ErrorType.IO, err.type)
      assert.equals('io failed', err.message)
    end)
  end)

  describe('wrap', function()
    it('should wrap existing error object with context', function()
      local original_err = errors.git_error('command failed')
      local wrapped = errors.wrap('Failed to fetch branch', original_err)

      assert.equals(errors.ErrorType.GIT, wrapped.type)
      assert.matches('Failed to fetch branch', wrapped.message)
      assert.matches('command failed', wrapped.message)
      assert.is_table(wrapped.context.wrapped)
      assert.equals(1, #wrapped.context.wrapped)
    end)

    it('should wrap multiple times', function()
      local err = errors.git_error('command failed')
      local wrapped1 = errors.wrap('Failed to fetch', err)
      local wrapped2 = errors.wrap('Failed to sync repo', wrapped1)

      assert.matches('Failed to sync repo', wrapped2.message)
      assert.equals(2, #wrapped2.context.wrapped)
    end)

    it('should convert string error to error object', function()
      local wrapped = errors.wrap('Context message', 'plain error')

      assert.equals(errors.ErrorType.UNKNOWN, wrapped.type)
      assert.matches('Context message', wrapped.message)
      assert.matches('plain error', wrapped.message)
    end)
  end)

  describe('try', function()
    it('should return result on success', function()
      local fn = function()
        return 'success'
      end

      local result, err = errors.try(fn)

      assert.equals('success', result)
      assert.is_nil(err)
    end)

    it('should return nil and error on failure', function()
      local fn = function()
        error('operation failed')
      end

      local result, err = errors.try(fn)

      assert.is_nil(result)
      assert.is_not_nil(err)
      assert.matches('operation failed', err.message)
    end)

    it('should wrap error with context', function()
      local fn = function()
        error('operation failed')
      end

      local result, err = errors.try(fn, 'Failed to process data')

      assert.is_nil(result)
      assert.is_not_nil(err)
      assert.matches('Failed to process data', err.message)
      assert.matches('operation failed', err.message)
    end)

    it('should handle function returning multiple values', function()
      local fn = function()
        return 'value1', 'value2'
      end

      local result, err = errors.try(fn)

      -- pcall returns true + results, so result will be the first return value
      assert.is_not_nil(result)
      assert.is_nil(err)
    end)
  end)

  describe('is_error', function()
    it('should return true for error objects', function()
      local err = errors.git_error('test error')

      assert.is_true(errors.is_error(err))
    end)

    it('should return false for non-error objects', function()
      assert.is_false(errors.is_error('string'))
      assert.is_false(errors.is_error(123))
      assert.is_false(errors.is_error(nil))
      assert.is_false(errors.is_error({}))
      assert.is_false(errors.is_error({ type = 'GitError' })) -- Missing message
    end)
  end)

  describe('format', function()
    it('should format error object with type', function()
      local err = errors.git_error('command failed')
      local formatted = errors.format(err)

      assert.matches('GitError', formatted)
      assert.matches('command failed', formatted)
    end)

    it('should not show type prefix for UNKNOWN errors', function()
      local err = errors.new(errors.ErrorType.UNKNOWN, 'unknown error')
      local formatted = errors.format(err)

      assert.not_matches('UnknownError', formatted)
      assert.matches('unknown error', formatted)
    end)

    it('should include suggestion from context', function()
      local err = errors.git_error('not a git repo', { suggestion = 'Run git init first' })
      local formatted = errors.format(err)

      assert.matches('not a git repo', formatted)
      assert.matches('Run git init first', formatted)
    end)

    it('should format string errors', function()
      local formatted = errors.format('plain error')

      assert.equals('plain error', formatted)
    end)
  end)

  describe('handler', function()
    it('should create error handler function', function()
      local handler = errors.handler(errors.ErrorType.GIT, 'Git operation failed')

      assert.is_function(handler)

      local result, err = handler('command not found')

      assert.is_nil(result)
      assert.is_not_nil(err)
      assert.equals(errors.ErrorType.GIT, err.type)
      assert.matches('Git operation failed', err.message)
      assert.matches('command not found', err.message)
    end)
  end)

  describe('log', function()
    -- Note: log() calls vim.notify which is hard to test
    -- We just verify it doesn't crash
    it('should log error object without crashing', function()
      local err = errors.git_error('test error')

      -- Should not throw
      assert.has_no.errors(function()
        errors.log(err)
      end)
    end)

    it('should log string error without crashing', function()
      assert.has_no.errors(function()
        errors.log('test error')
      end)
    end)

    it('should accept different log levels', function()
      local err = errors.git_error('test error')

      assert.has_no.errors(function()
        errors.log(err, 'error')
        errors.log(err, 'warn')
        errors.log(err, 'info')
      end)
    end)
  end)
end)
