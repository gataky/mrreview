-- tests/utils_spec.lua
-- Tests for utility functions

describe('utils', function()
  local utils = require('mrreviewer.utils')

  describe('trim', function()
    it('removes leading and trailing whitespace', function()
      assert.equals('hello', utils.trim('  hello  '))
      assert.equals('hello', utils.trim('\thello\n'))
      assert.equals('hello world', utils.trim('  hello world  '))
    end)

    it('handles empty strings', function()
      assert.equals('', utils.trim(''))
      assert.equals('', utils.trim('   '))
    end)

    it('handles nil', function()
      assert.equals('', utils.trim(nil))
    end)
  end)

  describe('is_empty', function()
    it('returns true for empty strings', function()
      assert.is_true(utils.is_empty(''))
      assert.is_true(utils.is_empty('   '))
      assert.is_true(utils.is_empty(nil))
    end)

    it('returns false for non-empty strings', function()
      assert.is_false(utils.is_empty('hello'))
      assert.is_false(utils.is_empty('  hello  '))
    end)
  end)

  describe('split', function()
    it('splits strings by delimiter', function()
      local result = utils.split('a,b,c', ',')
      assert.are.same({ 'a', 'b', 'c' }, result)
    end)

    it('handles single element', function()
      local result = utils.split('hello', ',')
      assert.are.same({ 'hello' }, result)
    end)
  end)

  describe('json_decode', function()
    it('decodes valid JSON', function()
      local json_str = '{"key": "value", "number": 42}'
      local result, err = utils.json_decode(json_str)

      assert.is_nil(err)
      assert.is_not_nil(result)
      assert.equals('value', result.key)
      assert.equals(42, result.number)
    end)

    it('handles invalid JSON', function()
      local result, err = utils.json_decode('not json')
      assert.is_nil(result)
      assert.is_not_nil(err)
    end)

    it('handles empty string', function()
      local result, err = utils.json_decode('')
      assert.is_nil(result)
      assert.equals('Empty JSON string', err)
    end)
  end)
end)
