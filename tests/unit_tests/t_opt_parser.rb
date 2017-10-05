#! /usr/bin/ruby

require_relative 'helper'

# Test the option parser
class GitarroOptionTest < Minitest::Test
  def set_option(hash, _s)
    opp = OptParser.new
    opp.options = hash
    ex = assert_raises SystemExit do
      opp.cmdline_options
    end
    assert_equal 1, ex.status
  end

  def test_partial_import
    hash =  { repo: 'gino/gitarro' }
    hash1 = { repo: 'gino/gitarro', context: 'python-t',
              description: 'functional', test: 'gino.sh' }
    set_option(hash, 'context')
    set_option(hash1, 'file_type')
  end

  def test_partial_import_descripition
    opp2 = OptParser.new
    full_hash = { repo: 'gino/gitarro', context: 'python-t',
                  test_file: 'gino.sh',
                  file_type: '.sh', git_dir: 'gitty' }
    opp2.options = full_hash
    options = opp2.cmdline_options
    optional_desc = 'use option -d to set a custom test description.'
    assert_equal(optional_desc, options[:description])
  end

  def test_optional_filetype
    opp2 = OptParser.new
    full_hash = { repo: 'gino/gitarro', context: 'python-t',
                  test_file: 'gino.sh',
                  git_dir: 'gitty' }
    opp2.options = full_hash
    options = opp2.cmdline_options
    assert_equal('notype', options[:file_type])
  end

  def test_custom_filetype
    opp2 = OptParser.new
    full_hash = { repo: 'gino/gitarro', context: 'python-t',
                  test_file: 'gino.sh', file_type: '.sh',
                  git_dir: 'gitty' }
    opp2.options = full_hash
    options = opp2.cmdline_options
    assert_equal('.sh', options[:file_type])
  end

  def test_full_option_import
    opp2 = OptParser.new
    full_hash = { repo: 'gino/gitarro', context: 'python-t',
                  description: 'functional', test_file: 'gino.sh',
                  file_type: '.sh', git_dir: 'gitty' }
    opp2.options = full_hash
    options = opp2.cmdline_options
    option_ass(options)
  end

  def test_default_cachehttp
    opp2 = OptParser.new
    full_hash = { repo: 'gino/gitarro', context: 'python-t',
                  test_file: 'gino.sh',
                  git_dir: 'gitty' }
    opp2.options = full_hash
    options = opp2.cmdline_options
    assert_equal('/tmp/gitarro', options[:cachehttp])
  end

  def test_custom_cachehttp
    opp2 = OptParser.new
    full_hash = { repo: 'gino/gitarro', context: 'python-t',
                  test_file: 'gino.sh', cachehttp: '/tmp/customd',
                  git_dir: 'gitty' }
    opp2.options = full_hash
    options = opp2.cmdline_options
    assert_equal('/tmp/customd', options[:cachehttp])
  end

  def option_ass(options)
    assert_equal('gino/gitarro', options[:repo])
    assert_equal('python-t', options[:context])
    assert_equal('functional', options[:description])
    assert_equal('gino.sh', options[:test_file])
    assert_equal('.sh', options[:file_type])
    assert_equal('gitty', options[:git_dir])
  end
end
