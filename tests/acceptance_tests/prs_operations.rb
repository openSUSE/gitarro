#! /usr/bin/ruby

require 'octokit'
require 'English'

# github octokit operation
class GitRemoteOperations
  attr_reader :repo, :client
  def initialize(repo)
    @repo = repo
    @client = Octokit::Client.new(netrc: true)
    Octokit.auto_paginate = true
  end

  def pr_by_number(num)
    client.pull_request(repo, num)
  end
end

# gitbot functional tests
# this class will remove the bash.sh manual stuff
class GitbotTesting
  attr_reader :repo, :client
  def initialize(repo)
    @repo = repo
    @client = Octokit::Client.new(netrc: true)
    Octokit.auto_paginate = true
  end

  def basic
    context = 'gitbot-dev2a'
    desc = 'dev-test'
    git_dir = '/tmp/ruby312'
    valid_test = '/tmp/gitbot.sh'
    url = 'https://github.com/openSUSE/gitbot/pull/8'
    ftype = '.rb'
    num = 30
    `echo '#! /bin/bash' > #{valid_test}`
    `chmod +x #{valid_test}`
    puts `ruby  ../../gitbot.rb -r #{repo}  -c #{context} -d #{desc} -g #{git_dir} -t #{valid_test} -f #{ftype} -u #{url} -P #{num}`
  end

  # Optional do we need to check the status during basic?
  # FIXME: add option -C
end

# MAIN TESTS

# Replace this with your repo
gitbotrepo = 'openSUSE/gitbot'

rgit = GitRemoteOperations.new(gitbotrepo)
test = GitbotTesting.new(gitbotrepo)

# assume that a PR Called FAKE-PR always exists.
# The implicit prereq. is the number 30 of PR

# get fake pr for testing
rgit.pr_by_number(30)

# 0 do a normal test
test.basic
