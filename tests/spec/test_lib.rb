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

  def first_pr_open
    prs = client.pull_requests(repo, state: 'open')
    prs.shift
  end

  def pr_by_number(num)
    client.pull_request(repo, num)
  end

  def commit_status(pr)
    client.status(repo, pr.head.sha)
  end

  def create_comment(pr, comment)
    client.add_comment(repo, pr.number, comment)
  end

  # FXIME: test if it works really
  def delete_c(comment_id)
    client.delete_comment(repo, comment_id)
  end
end

# gitbot functional tests
class GitbotTestingCmdLine
  attr_reader :repo, :client, :gitrem, :script,
              :ftype, :url, :git_dir, :valid_test
  def initialize(repo)
    @repo = repo
    @script = '../../gitbot.rb'
    @client = Octokit::Client.new(netrc: true)
    Octokit.auto_paginate = true
    @gitrem = GitRemoteOperations.new(repo)
    @ftype = '.'
    @git_dir = '/tmp/ruby312'
    @url = 'https://github.com/openSUSE/gitbot/pull/8'
    @valid_test = '/tmp/gitbot.sh'
    create_test_script(@valid_test)
  end

  def basic
    context = 'basic'
    desc = 'dev-test'
    num = 30
    gitbot_fixpr = "#{script} -r #{repo} -c #{context} -d #{desc}" \
               " -g #{git_dir} -t #{valid_test} -f #{ftype} -u #{url} -P #{num}"
    puts `ruby #{gitbot_fixpr}`
    return false if $CHILD_STATUS.exitstatus.nonzero?
    true
  end

  def basic_https
    context = 'basic-https'
    desc = 'dev-test'
    num = 30
    gb_http = "#{script} -r #{repo} -c #{context} -d #{desc} -g #{git_dir}" \
              " -t #{valid_test} -f #{ftype} -u #{url} -P #{num} --https"
    puts `ruby #{gb_http}`
    return false if $CHILD_STATUS.exitstatus.nonzero?
    true
  end

  def basic_check_test(comm_st, context, desc)
    # we want always to make the retrigger word,
    # so we have idempotency
    gitbot = "#{script} -r #{repo} -c #{context} -d #{desc} -g #{git_dir}" \
                    " -t #{valid_test} -f #{ftype} -u #{url} "
    # If it new, we need to add first the context
    unless context_present(comm_st, context)
      puts 'CONTEXT NOT FOUND for CHECK TEST'
      puts `ruby #{gitbot}`
    end
    puts `ruby #{gitbot} -C`
    # with check we have -1 has value ( used for retrigger)
    return false if $CHILD_STATUS.exitstatus.zero?
    puts `ruby #{gitbot}`
    true
  end

  def changelog_should_fail(com_st)
    context = 'changelog_shouldfail'
    desc = 'changelog_fail'
    gitbot = "#{script} -r #{repo} -c #{context} -d #{desc} -g #{git_dir}" \
                   " -t #{valid_test} -f #{ftype} -u #{url} "
    puts `ruby #{gitbot} --changelogtest`
    return false unless failed_status(com_st, context)
    true
  end

  def changelog_should_pass(com_st)
    context = 'changelog_shouldpass'
    desc = 'changelog_pass'
    `echo '#! /bin/bash' > #{valid_test}`
    `chmod +x #{valid_test}`
    gitbot = "#{script} -r #{repo} -c #{context} -d #{desc} -g #{git_dir}" \
                   " -t #{valid_test} -f #{ftype} -u #{url} "
    puts `ruby #{gitbot} --changelogtest`
    return false if failed_status(com_st, context)
    true
  end

  private

  def create_test_script(script)
    `echo '#! /bin/bash' > #{script}`
    `chmod +x #{script}`
  end

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

  def pending_status(comm_st, context)
    status = false
    (0..comm_st.statuses.size - 1).each do |pr_status|
      if comm_st.statuses[pr_status]['context'] == context &&
         comm_st.statuses[pr_status]['state'] == 'pending'
        status = true
      end
    end
    status
  end

  def context_present(comm_st, context)
    status = false
    (0..comm_st.statuses.size - 1).each do |pr_status|
      status = true if comm_st.statuses[pr_status]['context'] == context
    end
    status
  end
end
