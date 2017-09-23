#! /usr/bin/ruby

require 'octokit'
require 'English'

# Prerequisites: Have a netrc file
# git local operation
class GitLocalOperations
  def create_branch(branch_pr)
    `git branch #{branch_pr}`
  end

  def push_branch(branch_pr)
    `git push origin #{branch_pr}`
  end

  def make_commit(branch_pr)
   `git checkout #{branch_pr}`
   `touch fake.rb`
   `git commit -a -m "fake commit"`
  end
 
  def del_branch(branch_pr)
    `git branch -D #{branch_pr}`
  end
end

# github octokit operation
class GitRemoteOperations
  attr_reader :repo
  def initialize(repo)
    @repo = repo
    @client = Octokit::Client.new(netrc: true)
    Octokit.auto_paginate = true
  end

  def create_fake_pr(target_branch, branch_pr)
    @client.create_pull_request(repo, target_branch, branch_pr,
        'Fake PR title', 'Fake Request body')
  end

  def remove_fake_pr(pr_number)
    @client.close_pull_request(repo, pr_number)
  end
end

# gitbot tests
class GitbotTests
end


def main
  fake_br = 'fake_branch'
  gitbotrepo = 'openSUSE/gitbot'
  localgit = GitLocalOperations.new
  rgit = GitRemoteOperations.new(gitbotrepo)
  localgit.create_branch(fake_br)
  localgit.make_commit(fake_br)
  localgit.push_branch(fake_br)
  puts 'create fake PR'
  pr = rgit.create_fake_pr('master', fake_br)
  rgit.remove_fake_pr(pr.number)
  localgit.del_branch(fake_br)
end

main
