#! /usr/bin/ruby

require_relative 'helper'
require_relative '../lib/gitbot_backend.rb'

# Test the option parser
class GitbotGitop < Minitest::Test
  def test_gitop
    @full_hash = { repo: 'openSUSE/gitbot', context: 'python-t', description:
                   'functional', test_file: 'gino.sh', file_type: '.sh',
                   git_dir: 'gitty' }
    OptParser.options = @full_hash
    OptParser.gitbot_options
    gb = GitbotBackend.new
    gop = GitOp.new(gb.git_dir)
    puts gb.git_dir
    gop.ck_or_clone_git(gb.repo)
    FileUtils.rm_rf('gitty')
  end

  def test_cleanup
    Dir.chdir Dir.pwd
    FileUtils.rm_r('gitty') if File.directory?('gitty')
  end
end
