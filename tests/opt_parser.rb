#! /usr/bin/ruby

require_relative 'helper'

# Test the option parser
class GitbotOptionTest < Minitest::Test
  def set_option(hash, s)
    OptParser.options = hash
    ex = assert_raises OptionParser::MissingArgument do
      OptParser.gitbot_options
    end
    assert_equal("missing argument: #{s}", ex.message)
  end

  def test_partial_import
    hash =  { repo: 'gino/gitbot' }
    hash1 = { repo: 'gino/gitbot', context: 'python-t',
              description: 'functional', test: 'gino.sh' }
    set_option(hash, 'CONTEXT')
    set_option(hash1, 'SCRIPT FILE')
  end

  def test_full_option_import
    full_hash = { repo: 'gino/gitbot', context: 'python-t',
                  description: 'functional', test_file: 'gino.sh',
                  file_type: '.sh', git_dir: 'gitty' }
    OptParser.options = full_hash
    options = OptParser.gitbot_options
    assert_equal('gino/gitbot', options[:repo])
    assert_equal('python-t', options[:context])
    assert_equal('functional', options[:description])
    assert_equal('gino.sh', options[:test_file])
    assert_equal('.sh', options[:file_type])
    assert_equal('gitty', options[:git_dir])
  end
end
