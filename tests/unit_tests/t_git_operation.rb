#! /usr/bin/ruby

require_relative 'helper'
require 'ostruct'
# Test the option parser
class GitbotGitop < Minitest::Test
  def test_gitop
    @full_hash = { repo: 'openSUSE/gitbot', context: 'python-t', description:
                   'functional', test_file: 'gino.sh', file_type: '.sh',
                   git_dir: 'gitty', https: false, pr_number: 5 }
    gb = Backend.new(@full_hash)
    gop = GitOp.new(gb.git_dir, @full_hash)
    puts gb.git_dir
    gop.get_pr(@full_hash[:pr_number])
  end
end
