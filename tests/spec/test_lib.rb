#! /usr/bin/ruby

require 'octokit'
require 'English'

# allow flexibility
# if called in rspec dir or from rake file
inside_spec = '././../gitarro.rb'
GITARRO_BIN = inside_spec if File.file?(inside_spec)
GITARRO_BIN = 'gitarro.rb'.freeze unless File.file?(inside_spec)
raise 'cannot find gitarrobin' unless File.file?(GITARRO_BIN)

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

  def change_description(pr, description)
    client.update_pull_request(repo, pr.number, body: description)
  end

  def delete_c(comment_id)
    client.delete_comment(repo, comment_id)
  end
end

# Fondamental tests
module BasicTests
  def basic(num)
    context = 'basic'
    desc = 'dev-test'
    gitarro_fixpr = "#{script} -r #{repo} -c #{context} -d #{desc}" \
               " -g #{git_dir} -t #{valid_test} -f #{ftype} -u #{url} -P #{num}"
    puts `ruby #{gitarro_fixpr}`
    $CHILD_STATUS.exitstatus.nonzero? ? false : true
  end

  def basic_https(num)
    context = 'basic-https'
    desc = 'dev-test'
    gb_http = "#{script} -r #{repo} -c #{context} -d #{desc} -g #{git_dir}" \
              " -t #{valid_test} -f #{ftype} -u #{url} -P #{num} --https"
    puts `ruby #{gb_http}`
    $CHILD_STATUS.exitstatus.nonzero? ? false : true
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
    puts `ruby #{gitarro}`
    return true if $CHILD_STATUS.exitstatus.zero?

    false
  end


end

# gitarro functional tests
class GitarroTestingCmdLine
  attr_reader :repo, :client, :gitrem, :script,
              :ftype, :url, :git_dir, :valid_test

  include BasicTests

  def initialize(repo, git_dir)
    @repo = repo
    @script = GITARRO_BIN
    @client = Octokit::Client.new(netrc: true)
    Octokit.auto_paginate = true
    @gitrem = GitRemoteOperations.new(repo)
    @ftype = '.'
    @git_dir = git_dir
    @url = 'https://github.com/openSUSE/gitarro/pull/8'
    @valid_test = '/tmp/gitarro.sh'
    # create for all test a valid test script
    create_test_script(@valid_test)
  end

  def only_onetime(comm_st, cont)
    desc = 'run only 1time with same context'
    2.times do |n|
      `echo '#! /bin/bash' > #{valid_test}`
      `echo 'touch /tmp/foo#{n.to_s}' > #{valid_test}`
      `chmod +x #{valid_test}`
      gitarro = "#{script} -r #{repo} -c #{cont} -d #{desc} -g #{git_dir}" \
                   " -t #{valid_test} -u #{url} "
      puts `ruby #{gitarro}`
    end
    raise 'GITARRO SHOULDNT FAIL' if failed_status(comm_st, cont)

    File.file?('/tmp/foo2')
  end

  def changed_since(comm_st, sec, cont)
    gitarro = "#{script} -r #{repo} -c #{cont} -d #{cont} -g #{git_dir}" \
              " -t #{valid_test} -f #{ftype} -u #{url}"
    changed_since_param = "--changed_since #{sec}" if sec >= 0
    puts stdout = `ruby #{gitarro} #{changed_since_param}`
    [failed_status(comm_st, cont) && (sec > 0 || sec < 0) ? false : true,
     stdout]
  end

  def force_test_with_specific_pr(comm_st, pr_number, cont)
    gitarro = "#{script} --force_test --PR #{pr_number} -r #{repo} -c #{cont}" \
              " -d #{cont} -g #{git_dir} -t #{valid_test} -f #{ftype} -u #{url}"

    puts `ruby #{gitarro}`
    raise 'GITARRO SHOULDNT FAIL' if failed_status(comm_st, cont)

    true
  end

  def noshallow(comm_st, cont)
    gitarro = "#{script} -r #{repo} -c #{cont} -d noshallowclone  -g #{git_dir}" \
              " -t #{valid_test} -f #{ftype} -u #{url} --noshallow"
  
    puts `ruby #{gitarro}`
    raise 'GITARRO SHOULDNT FAIL' if failed_status(comm_st, cont)

    true
  end

  def env_test(cont)
    desc = 'env variable are passed'
    valid_test = '/tmp/environ.sh'
    `echo '#! /bin/bash' > #{valid_test}`
    `echo 'echo "GITARRO_PR_NUMBER: $GITARRO_PR_NUMBER"' >> #{valid_test}`
    `echo 'echo "GITARRO_PR_TITLE: $GITARRO_PR_TITLE"' >> #{valid_test}`
    `echo 'echo "GITARRO_PR_AUTHOR: $GITARRO_PR_AUTHOR"' >> #{valid_test}`
    `echo 'echo "GITARRO_PR_TARGET_REPO: $GITARRO_PR_TARGET_REPO"' >> #{valid_test}`
    `chmod +x #{valid_test}`
    gitarro = "#{script} -r #{repo} -c #{cont} -d #{desc} -g #{git_dir}" \
                   " -t #{valid_test} -u #{url} "
    puts stdout = `ruby #{gitarro}`
    stdout
  end

  private

  def create_test_script(script)
    `echo '#! /bin/bash' > #{script}`
    `chmod +x #{script}`
  end

  def failed_status(comm_st, context)
    (0..comm_st.statuses.size - 1).each do |pr_status|
      if comm_st.statuses[pr_status]['context'] == context &&
         comm_st.statuses[pr_status]['state'] == 'failure'
        return true
      end
    end
    false
  end

  def pending_status(comm_st, context)
    (0..comm_st.statuses.size - 1).each do |pr_status|
      if comm_st.statuses[pr_status]['context'] == context &&
         comm_st.statuses[pr_status]['state'] == 'pending'
        return true
      end
    end
    false
  end

  def context_present(comm_st, context)
    (0..comm_st.statuses.size - 1).each do |pr_status|
      return true if comm_st.statuses[pr_status]['context'] == context
    end
    false
  end
end
