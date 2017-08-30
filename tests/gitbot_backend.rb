#! /usr/bin/ruby

require_relative 'helper'
require_relative '../lib/gitbot_backend.rb'

# Test the option parser
class GitbotBackendTest2 < Minitest::Test
  def test_full_option_import2
    @full_hash = { repo: 'gino/gitbot', context: 'python-t', description: 'functional', test_file: 'gino.sh', file_type: '.sh', git_dir: 'gitty' }
    OptParser.options = @full_hash
    options = OptParser.get_options
    gitbot = GitbotBackend.new
    gitbot.options = options
    puts gitbot.j_status
    gitbot.j_status = 'foo'
    assert_equal('gino/gitbot', gitbot.repo)
    assert_equal('python-t', gitbot.context)
    assert_equal('functional', gitbot.description)
    assert_equal('gino.sh', gitbot.test_file)
    assert_equal('.sh', gitbot.file_type)
    assert_equal('gitty', gitbot.git_dir)
  end
end
