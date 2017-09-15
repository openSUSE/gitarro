#! /usr/bin/ruby

require_relative 'helper'
require_relative '../lib/gitbot_backend.rb'
require 'ostruct'
# Test the option parser
class GitbotGitop < Minitest::Test
  def test_gitop
    @full_hash = { repo: 'openSUSE/gitbot', context: 'python-t', description:
                   'functional', test_file: 'gino.sh', file_type: '.sh',
                   git_dir: 'gitty' }
    OptParser.options = @full_hash
    OptParser.gitbot_options
    gb = GitbotBackend.new
    # crate fake object for internal class external repo
    pr = 'fake'
    gop = GitOp.new(gb.git_dir, pr)
    puts gb.git_dir
    gop.ck_or_clone_git(gb.repo)
  end
end
