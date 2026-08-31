#! /usr/bin/ruby

require_relative 'helper'

Dir.chdir Dir.pwd
# Test the option parser
class BackendTest2 < Minitest::Test
  def setup
    @full_hash = { repo: 'gino/gitarro', context: 'python-t', description:
                   'functional', test_file: 'gino.sh', file_type: '.sh',
                   git_dir: 'gitty', changed_since: -1 }
  end

  def test_full_option_import2
    gitarro = Backend.new(@full_hash)
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
    @full_hash[:test_file] = 'test_data/script_ok.sh'
    gbex = TestExecutor.new(@full_hash)
    ck_files(gbex)
  end

  def ck_files(gbex)
    assert_equal('success', gbex.run_script)
    gbex.test_file = 'test_data/script_fail.sh'
    assert_equal('failure', gbex.run_script)
  end

  def test_run_noscript
    @full_hash[:test_file] = 'test_data/script_missing.sh'
    gbex = TestExecutor.new(@full_hash)
    assert_equal('failure', gbex.run_script)
  end

  def test_filter_files_by_type
    gitarro = Backend.new(@full_hash)
    class << gitarro
        public :filter_files_by_type
    end

    agent = Sawyer::Agent.new("https://api.example.com")
    test = Sawyer::Resource.new(agent, { filename: 'path/test.sh'})
    item1 = Sawyer::Resource.new(agent, { filename: 'item1.yaml'})
    item2 = Sawyer::Resource.new(agent, { filename: 'item2.yaml'})

    actual = gitarro.filter_files_by_type([test, item1, item2], '.sh')
    assert_equal(['path/test.sh'], actual)

    actual = gitarro.filter_files_by_type([test, item1, item2], 'path/')
    assert_equal(['path/test.sh'], actual)

    actual = gitarro.filter_files_by_type([test, item1, item2], 'item.*\.yaml')
    assert_equal(['item1.yaml', 'item2.yaml'], actual)
  end
end
