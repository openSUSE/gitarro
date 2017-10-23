#! /usr/bin/ruby

require_relative 'test_lib.rb'

# this small class is used for setup and run Rspec
# locally on forked repos
class SetupRspec
  def self.custom_git_repo
    git_repo = ENV['repo']
    no_repo = 'No gitarro repo was given! use your forked repo'
    raise ArgumentError, no_repo if git_repo.nil?
    git_repo
  end

  def self.pr_number
    number = ENV['pr_num']
    no_pr = 'No pr Number where to run tests was given'
    raise ArgumentError, no_pr if number.nil?
    number
  end
end

# setup testenv ( if needed)
GIT_REPO = SetupRspec.custom_git_repo
puts 'Using following github repo: ' + GIT_REPO
# this is used in only 2/3 tests
PR_NUMBER = SetupRspec.pr_number
puts 'Using pull_request number: ' + PR_NUMBER
