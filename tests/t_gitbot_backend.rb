#! /usr/bin/ruby

require_relative 'helper'
require_relative '../lib/gitbot_backend.rb'

Dir.chdir Dir.pwd
# Test the option parser
class GitbotBackendTest2 < Minitest::Test
  def test_full_option_import2
    @full_hash = { repo: 'gino/gitbot', context: 'python-t', description:
                   'functional', test_file: 'gino.sh', file_type: '.sh',
                   git_dir: 'gitty' }
    OptParser.options = @full_hash
    OptParser.gitbot_options
    gitbot = GitbotBackend.new
    puts gitbot.j_status
    gitbot.j_status = 'foo'
    gitbot_assert(gitbot)
  end

  def gitbot_assert(gitbot)
    assert_equal('gino/gitbot', gitbot.repo)
    assert_equal('python-t', gitbot.context)
    assert_equal('functional', gitbot.description)
    assert_equal('gino.sh', gitbot.test_file)
    assert_equal('.sh', gitbot.file_type)
    assert_equal('gitty', gitbot.git_dir)
  end

  def test_run_script
    @full_hash = { repo: 'gino/gitbot', context: 'python-t', description:
                   'functional', test_file: 'test_data/script_ok.sh',
                   file_type: '.sh', git_dir: 'gitty' }
    OptParser.options = @full_hash
    gb = GitbotBackend.new
    OptParser.gitbot_options
    ck_files(gb)
    test_file = 'nofile.txt'
    assert_file_non_ex(gb, test_file)
  end

  def ck_files(gb)
    gb.run_script
    assert_equal('success', gb.j_status)
    gb.test_file = 'test_data/script_fail.sh'
    gb.run_script
    assert_equal('failure', gb.j_status)
  end

  def assert_file_non_ex(gb, test_file)
    ex = assert_raises RuntimeError do
      gb.test_file = test_file
      gb.run_script
    end
    assert_equal("'#{test_file}\' doesn't exists.Enter valid file, -t option",
                 ex.message)
  end
end
