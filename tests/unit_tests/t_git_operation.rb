#! /usr/bin/ruby

require_relative 'helper'
require 'ostruct'
# Test the option parser
class gitarroGitop < Minitest::Test
  def test_gitop
    @full_hash = { repo: 'openSUSE/gitarro', context: 'python-t', description:
                   'functional', test_file: 'gino.sh', file_type: '.sh',
                   git_dir: 'gitty', https: true }
    gb = Backend.new(@full_hash)
    # crate fake object for internal class external repo
    # FIXME: this could improved creating a full mock obj
    pr = 'fake'
    gop = GitOp.new(gb.git_dir, pr, @full_hash)
    puts gb.git_dir
    gop.ck_or_clone_git
  end
end
