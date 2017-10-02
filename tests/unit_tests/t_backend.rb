#! /usr/bin/ruby

require_relative 'helper'

Dir.chdir Dir.pwd
# Test the option parser
class BackendTest2 < Minitest::Test
  def test_full_option_import2
    @full_hash = { repo: 'gino/gitarro', context: 'python-t', description:
                   'functional', test_file: 'gino.sh', file_type: '.sh',
                   git_dir: 'gitty', no_merge_upstream: true }
    gitarro = Backend.new(@full_hash)
    puts gitarro.j_status
    gitarro.j_status = 'foo'
    gitarro_assert(gitarro)
  end

  def gitarro_assert(gitarro)
    assert_equal('gino/gitarro', gitarro.repo)
    assert_equal('python-t', gitarro.context)
    assert_equal('functional', gitarro.description)
    assert_equal('gino.sh', gitarro.test_file)
    assert_equal('.sh', gitarro.file_type)
    assert_equal('gitty', gitarro.git_dir)
  end

  def test_run_script
    @full_hash = { repo: 'gino/gitarro', context: 'python-t', description:
                   'functional', test_file: 'test_data/script_ok.sh',
                   file_type: '.sh', git_dir: 'gitty',
                   no_merge_upstream: true }
    gbex = TestExecutor.new(@full_hash)
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
