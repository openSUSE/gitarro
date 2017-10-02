#! /usr/bin/ruby

require 'octokit'
require 'English'

# this might change
GITARRO_BIN = '../../gitarro.rb'


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

  def commit_status(pr)
    client.status(repo, pr.head.sha)
  end

  def create_comment(pr, comment)
    client.add_comment(repo, pr.number, comment)
  end

  def delete_c(comment_id)
    client.delete_comment(repo, comment_id)
  end
end

# gitarro functional tests
class GitarroTestingCmdLine
  attr_reader :repo, :client, :gitrem, :script,
              :ftype, :url, :git_dir, :valid_test
  def initialize(repo)
    @repo = repo
    @script = GITARRO_BIN
    @client = Octokit::Client.new(netrc: true)
    Octokit.auto_paginate = true
    @gitrem = GitRemoteOperations.new(repo)
    @ftype = '.'
    @git_dir = '/tmp/ruby312'
    @url = 'https://github.com/openSUSE/gitarro/pull/8'
    @valid_test = '/tmp/gitarro.sh'
    create_test_script(@valid_test)
  end

  def basic(num)
    context = 'basic'
    desc = 'dev-test'
    gitarro_fixpr = "#{script} -r #{repo} -c #{context} -d #{desc}" \
               " -g #{git_dir} -t #{valid_test} -f #{ftype} -u #{url} -P #{num}"
    puts `ruby #{gitarro_fixpr}`
    return false if $CHILD_STATUS.exitstatus.nonzero?
    true
  end

  def basic_https(num)
    context = 'basic-https'
    desc = 'dev-test'
    gb_http = "#{script} -r #{repo} -c #{context} -d #{desc} -g #{git_dir}" \
              " -t #{valid_test} -f #{ftype} -u #{url} -P #{num} --https"
    puts `ruby #{gb_http}`
    return false if $CHILD_STATUS.exitstatus.nonzero?
    true
  end

  def basic_check_test(comm_st, context, desc)
    # we want always to make the retrigger word,
    # so we have idempotency
    gitarro = "#{script} -r #{repo} -c #{context} -d #{desc} -g #{git_dir}" \
                    " -t #{valid_test} -f #{ftype} -u #{url} "
    # If it new, we need to add first the context
    unless context_present(comm_st, context)
      puts 'INFO: CONTEXT NOT FOUND for CHECK TEST'
      puts `ruby #{gitarro}`
    end
    puts `ruby #{gitarro} -C`
    # with check we have -1 has value ( used for retrigger)
    return false if $CHILD_STATUS.exitstatus.zero?
    puts `ruby #{gitarro}`
    true
  end

  def changelog_should_fail(com_st)
    context = 'changelog_shouldfail'
    desc = 'changelog_fail'
    gitarro = "#{script} -r #{repo} -c #{context} -d #{desc} -g #{git_dir}" \
                   " -t #{valid_test} -f #{ftype} -u #{url} "
    puts `ruby #{gitarro} --changelogtest`
    return false unless failed_status(com_st, context)
    true
  end

  def changelog_should_pass(com_st)
    context = 'changelog_shouldpass'
    desc = 'changelog_pass'
    `echo '#! /bin/bash' > #{valid_test}`
    `chmod +x #{valid_test}`
    gitarro = "#{script} -r #{repo} -c #{context} -d #{desc} -g #{git_dir}" \
                   " -t #{valid_test} -f #{ftype} -u #{url} "
    puts `ruby #{gitarro} --changelogtest`
    return false if failed_status(com_st, context)
    true
  end

  def file_type_unset(comm_st, cont)
    desc = 'we dont filter particular files'
    `echo '#! /bin/bash' > #{valid_test}`
    `chmod +x #{valid_test}`
    gitarro = "#{script} -r #{repo} -c #{cont} -d #{desc} -g #{git_dir}" \
                   " -t #{valid_test} -u #{url} "
    puts `ruby #{gitarro}`
    return false if failed_status(comm_st, cont)
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
