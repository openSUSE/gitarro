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

  def get_first_pr_open
    prs = client.pull_requests(repo, state: 'open')
    prs.shift
  end

  def pr_by_number(num)
    client.pull_request(repo, num)
  end

  def commit_status(pr)
    comm_st = client.status(repo, pr.head.sha)
  end

  def create_comment(pr, comment)
    client.create_commit_comment(repo, pr.head.sha, comment)
  end

  def delete_c(comment_id)
    client.delete_commit_comment(repo, comment_id)
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

  public

  def basic
    context = 'changelog'
    desc = 'dev-test'
    git_dir = '/tmp/ruby312'
    valid_test = '/tmp/gitbot.sh'
    url = 'https://github.com/openSUSE/gitbot/pull/8'
    ftype = '.rb'
    num = 30
    `echo '#! /bin/bash' > #{valid_test}`
    `chmod +x #{valid_test}`
    puts `ruby  ../../gitbot.rb -r #{repo}  -c #{context} -d #{desc} -g #{git_dir} -t #{valid_test} -f #{ftype} -u #{url} -P #{num}`
    raise 'BASIC TEST FAILED' if $CHILD_STATUS.exitstatus.nonzero?
  end

  def changelog_should_fail(com_st)
    context = 'changelog_shouldfail'
    desc = 'changelog_fail'
    git_dir = '/tmp/ruby312'
    valid_test = '/tmp/gitbot.sh'
    url = 'https://github.com/openSUSE/gitbot/pull/8'
    ftype = '.rb'
    num = 30
    `echo '#! /bin/bash' > #{valid_test}`
    `chmod +x #{valid_test}`
    puts `ruby  ../../gitbot.rb -r #{repo}  -c #{context} -d #{desc} -g #{git_dir} -t #{valid_test} -f #{ftype} -u #{url} --changelogtest`
    raise 'chanelog test should fail!' unless failed_status(com_st, context)
  end

  def changelog_should_pass(com_st)
    context = 'changelog_shouldpass'
    desc = 'changelog_pass'
    git_dir = '/tmp/ruby312'
    valid_test = '/tmp/gitbot.sh'
    url = 'https://github.com/openSUSE/gitbot/pull/8'
    ftype = '.rb'
    num = 30
    `echo '#! /bin/bash' > #{valid_test}`
    `chmod +x #{valid_test}`
    puts `ruby  ../../gitbot.rb -r #{repo}  -c #{context} -d #{desc} -g #{git_dir} -t #{valid_test} -f #{ftype} -u #{url} --changelogtest`
    raise 'chanelog test should pass!' if failed_status(com_st, context)
  end

  private

  def failed_status(comm_st, context)
    status = false
    (0..comm_st.statuses.size - 1).each do |pr_status|
      if comm_st.statuses[pr_status]['context'] == context &&
         comm_st.statuses[pr_status]['state'] == 'failure'
        status = true
      end
    end
    status
  end
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

pr = rgit.get_first_pr_open

# ********** TESTS *************
# 0 do a normal test

puts '--- BASIC TEST ---'
test.basic
comm_st = rgit.commit_status(pr)

# FIXME: add option -C tests (check)

# 1 We assume that no PRs on gitbot have a file .changes (99% is the case)
puts '--- CHANGELOG SHOULD FAIL TEST ---'
test.changelog_should_fail(comm_st)

# 2 create comment "no changelog needed!", for making the changelog test passing
comment = rgit.create_comment(pr, 'no changelog needed!')
cont = 'changelog_shouldpass'
# in this way we are always sure that we can rerun the tests
# with the retrigger option
rcomment = rgit.create_comment(pr, "@gitbot rerun #{cont} !!!")

comm_st2 = rgit.commit_status(pr)
begin
  test.changelog_should_pass(comm_st2)
rescue
  raise
ensure
  # remove always the comment if something went wrong
  rgit.delete_c(comment.id)
  rgit.delete_c(rcomment.id)
end
