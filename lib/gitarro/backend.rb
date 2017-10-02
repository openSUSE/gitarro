#! /usr/bin/ruby

require 'octokit'
require 'optparse'
require 'English'
require_relative 'opt_parser'
require_relative 'git_op'

# This is a private class, which has the task to execute/run tests
# called by Backend
class TestExecutor
  def initialize(options)
    @options = options
    @options.each do |key, value|
      instance_variable_set("@#{key}", value)
      self.class.send(:attr_accessor, key)
    end
  end

  # this will clone the repo and execute the tests
  def pr_test(pr)
    git = GitOp.new(@git_dir, @options)
    # Get the PR
    git.get_pr(pr.number, pr.base.ref)
    # do valid tests and store the result
    test_status = run_script
    test_status
  end

  # run validation script for validating the PR.
  def run_script
    script_exists?(@test_file)
    puts `#{@test_file}`
    $CHILD_STATUS.exitstatus.nonzero? ? 'failure' : 'success'
  end

  private

  def script_exists?(script)
    n_exist = "\'#{script}\' doesn't exists.Enter valid file, -t option"
    raise n_exist if File.file?(script) == false
  end
end

# this the public class is the backend of gitarro,
# were we execute the tests and so on
class Backend
  attr_accessor :j_status, :options, :client, :pr_files, :gbexec
  # public method of backend
  def initialize(option = nil)
    Octokit.auto_paginate = true
    @client = Octokit::Client.new(netrc: true)
    @options = option.nil? ? OptParser.new.cmdline_options : option
    @j_status = ''
    @pr_files = []
    # each options will generate a object variable dinamically
    @options.each do |key, value|
      instance_variable_set("@#{key}", value)
      self.class.send(:attr_accessor, key)
    end
    @gbexec = TestExecutor.new(@options)
  end

  def create_status(pr_head_sha, status)
    client.create_status(@repo, pr_head_sha, status, context: @context,
                                                     description: @description,
                                                     target_url: @target_url)
  end

  # public method for get prs opens
  # given a repo
  def open_prs
    prs = @client.pull_requests(@repo, state: 'open')
    puts 'no Pull request OPEN on the REPO!' unless prs.any?
    prs
  end

  def in_mergeable_state(pr)
    if pr.mergeable_state != 'clean'
      create_status(pr.head.sha, 'failure')
      magicword(@repo, pr.number, @context)
      return false
    end
    true
  end

  # public for etrigger the test
  def retrigger_check(pr)
    return unless retrigger_needed?(pr)
    create_status(pr.head.sha, 'pending')
    exit 1 if @check
    launch_test_and_setup_status(pr)
    j_status == 'success' ? exit(0) : exit(1)
  end

  # public always rerun tests against the pr number if this exists
  def trigger_by_pr_number(pr)
    return false if @pr_number.nil? || @pr_number != pr.number
    puts "Got triggered by PR_NUMBER OPTION, rerunning on #{@pr_number}"
    launch_test_and_setup_status(pr)
    true
  end

  # public method, trigger changelogtest if option active
  def changelog_active(pr, comm_st)
    @changelog_test || changelog_changed(pr, comm_st) ? true : false
  end

  def unreviewed_pr_test(pr, comm_st)
    return unless unreviewed_pr_ck(comm_st)
    pr_all_files_type(@repo, pr.number, @file_type)
    return if empty_files_changed_by_pr
    # gb.check is true when there is a job running as scheduler
    # which doesn't execute the test but trigger another job
    return false if @check
    launch_test_and_setup_status(pr)
    true
  end

  def reviewed_pr_test(comm_st, pr)
    # if PR status is not on pending and the context is not set,
    #  we dont run the tests
    return false unless context_pr(comm_st) == false ||
                        pending_pr(comm_st) == true
    pr_all_files_type(@repo, pr.number, @file_type)
    return true if changelog_active(pr, comm_st)
    return false unless @pr_files.any?
    exit 1 if @check
    launch_test_and_setup_status(@repo, pr)
    true
  end

  private

  # this function setup first pending to PR, then execute the tests
  # then set the status according to the results of script executed.
  # pr_head = is the PR branch
  # base = is a the upstream branch, where the pr targets
  def launch_test_and_setup_status(pr)
    # pending
    create_status(pr.head.sha, 'pending')
    # do tests
    @j_status = gbexec.pr_test(pr)
    # set status
    create_status(pr.head.sha, @j_status)
  end

  # this function will check if the PR contains in comment the magic word
  # # for retrigger all the tests.
  def magicword(repo, pr_number, context)
    magic_word_trigger = "gitarro rerun #{context} !!!"
    pr_comment = @client.issue_comments(repo, pr_number)
    # a pr contain always a comments, cannot be nil
    pr_comment.each do |com|
      # delete comment otherwise it will be retrigger infinetely
      if com.body.include? magic_word_trigger
        @client.delete_comment(repo, com.id)
        return true
      end
    end
    false
  end

  # check all files of a Prs Number if they are a specific type
  # EX: Pr 56, we check if files are '.rb'
  def pr_all_files_type(repo, pr_number, type)
    files = @client.pull_request_files(repo, pr_number)
    @pr_files = filter_files_by_type(files, type)
  end

  # by default type is 'notype', which imply we get all files
  # modified by a Pull Request
  # otherwise we filter the file '.rb' type or fs ''
  def filter_files_by_type(files, type)
    # ff: filtered files array
    ff = []
    if type == 'notype'
      ff = files
    else
      files.each { |f| ff.push(f.filename) if f.filename.include? type }
    end
    ff
  end

  # check if the commit of a pr is on pending
  def pending_pr(comm_st)
    # 2) pending
    (0..comm_st.statuses.size - 1).each do |pr_status|
      if comm_st.statuses[pr_status]['context'] == @context &&
         comm_st.statuses[pr_status]['state'] == 'pending'
        return true
      end
    end
    false
  end

  # if the Pr contains magic word, test changelog
  # is true
  def magic_comment(repo, pr_num)
    @client.issue_comments(repo, pr_num).each do |com|
      if com.body.include?('no changelog needed!')
        @j_status = 'success'
        break
      end
    end
  end

  # check it the cm of pr contain the context from gitarro already
  def context_pr(cm_st)
    # 1) context_present == false  triggers test. >
    # this means  the PR is not with context tagged
    (0..cm_st.statuses.size - 1).each do |pr_status|
      return true if cm_st.statuses[pr_status]['context'] == @context
    end
    false
  end

  # if the pr has travis test and one custom, we will have 2 elements.
  # in this case, if the 1st element doesn't have the state property
  # state property is "pending", failure etc.
  # if we don't have this, so we have 0 status
  # the PRs is "unreviewed"
  def unreviewed_pr_ck(comm_st)
    puts comm_st.statuses[0]['state']
    return false
  rescue NoMethodError
    return true
  end

  def success_status?(comm_st)
    (0..comm_st.statuses.size - 1).each do |pr_status|
      if comm_st.statuses[pr_status]['context'] == @context &&
         comm_st.statuses[pr_status]['state'] == 'success'
        return true
      end
    end
    false
  end

  def failed_status?(comm_st)
    (0..comm_st.statuses.size - 1).each do |pr_status|
      if comm_st.statuses[pr_status]['context'] == @context &&
         comm_st.statuses[pr_status]['state'] == 'failure'
        return true
      end
    end
    false
  end

  # control if the pr change add any files, specified
  # it can be also a dir
  def empty_files_changed_by_pr
    return if pr_files.any?
    puts "no files of type #{@file_type} found! skipping"
    true
  end

  def do_changelog_test(pr)
    @j_status = 'failure'
    pr_all_files_type(repo, pr.number, @file_type)
    # if the pr contains changes on .changes file, test ok
    @j_status = 'success' if @pr_files.any?
    magic_comment(repo, pr.number)
    create_status(pr.head.sha, @j_status)
    true
  end

  # do the changelog test and set status
  def changelog_changed(pr, comm_st)
    return false unless @changelog_test
    # only execute 1 time, don"t run if test is failed, or ok
    return false if failed_status?(comm_st) || success_status?(comm_st)
    do_changelog_test(pr)
  end

  def retrigger_needed?(pr)
    # we want redo sometimes tests
    return false unless magicword(@repo, pr.number, @context)
    # changelog trigger
    if @changelog_test
      do_changelog_test(pr)
      return false
    end
    pr_all_files_type(@repo, pr.number, @file_type)
    # if check is set, the comment in the trigger job will be del.
    # so setting it to pending, it will be remembered
    @pr_files.any ? true : false
  end
end
