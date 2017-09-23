#! /usr/bin/ruby

require_relative 'helper'
require 'ostruct'
# Test the option parser
class GitbotGitop < Minitest::Test
  def test_gitop
    @full_hash = { repo: 'openSUSE/gitbot', context: 'python-t', description:
                   'functional', test_file: 'gino.sh', file_type: '.sh',
                   git_dir: 'gitty' }
    gb = GitbotBackend.new(@full_hash)
    # crate fake object for internal class external repo
    # FIXME: this could improved creating a full mock obj
    pr = 'fake'
    gop = GitOp.new(gb.git_dir, pr)
    puts gb.git_dir
    gop.ck_or_clone_git(gb.repo)
  end
end
