#! /usr/bin/ruby

require_relative 'helper'

Dir.chdir Dir.pwd
# Test the option parser
class GitbotBackendTest2 < Minitest::Test
  def test_full_option_import2
    @full_hash = { repo: 'gino/gitbot', context: 'python-t', description:
                   'functional', test_file: 'gino.sh', file_type: '.sh',
                   git_dir: 'gitty' }
    gitbot = GitbotBackend.new(@full_hash)
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
    gbex = GitbotTestExecutor.new(@full_hash)
    ck_files(gbex)
    test_file = 'nofile.txt'
    assert_file_non_ex(gbex, test_file)
  end

  def ck_files(gbex)
    assert_equal('success', gbex.run_script)
    gbex.test_file = 'test_data/script_fail.sh'
    assert_equal('failure', gbex.run_script)
  end

  def assert_file_non_ex(gbex, test_file)
    ex = assert_raises RuntimeError do
      gbex.test_file = test_file
      gbex.run_script
    end
    assert_equal("'#{test_file}\' doesn't exists.Enter valid file, -t option",
                 ex.message)
  end
end
