#! /usr/bin/ruby

require 'octokit'
require 'optparse'
require 'English'
require_relative 'opt_parser'
require_relative 'git_op'

# This is a private class, which has the task to execute/run tests
# called by GitbotBackend
class GitbotTestExecutor
  def initialize(options)
    @options = options
    @options.each do |key, value|
      instance_variable_set("@#{key}", value)
      self.class.send(:attr_accessor, key)
    end
  end

  # this will clone the repo and execute the tests
  def pr_test(pr)
    git = GitOp.new(@git_dir, pr, @options)
    # merge PR-branch to upstream branch
    git.merge_pr_totarget(pr.base.ref, pr.head.ref)
    # do valid tests and store the result
    test_status = run_script
    # del branch
    git.del_pr_branch(pr.base.ref, pr.head.ref)
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

# this the public class is the backend of gitbot,
# were we execute the tests and so on
class GitbotBackend
  attr_accessor :j_status, :options, :client, :pr_files, :gbexec
  # public method of backend
  def initialize(option = nil)
    Octokit.auto_paginate = true
    @client = Octokit::Client.new(netrc: true)
    @options = option.nil? ? OptParser.new.gitbot_options : option
    @j_status = ''
    @pr_files = []
    # each options will generate a object variable dinamically
    @options.each do |key, value|
      instance_variable_set("@#{key}", value)
      self.class.send(:attr_accessor, key)
    end
    @gbexec = GitbotTestExecutor.new(@options)
  end

  # public method for get prs opens
  # given a repo
  def open_prs
    prs = @client.pull_requests(@repo, state: 'open')
    puts 'no Pull request OPEN on the REPO!' unless prs.any?
    prs
  end

  # this function will retrigger the test
  def retrigger_check(pr)
    return unless retrigger_needed?(pr)
    client.create_status(@repo, pr.head.sha, 'pending',
                         context: @context, description: @description,
                         target_url: @target_url)
    exit 1 if @check
    launch_test_and_setup_status(@repo, pr)
    j_status == 'success' ? exit(0) : exit(1)
  end

  # we always rerun tests against the pr number if this exists
  def trigger_by_pr_number(pr)
    return false if @pr_number.nil?
    return false if @pr_number != pr.number
    puts "Got triggered by PR_NUMBER OPTION, rerunning on #{@pr_number}"
    launch_test_and_setup_status(@repo, pr)
    true
  end

  # check all files of a Prs Number if they are a specific type
  # EX: Pr 56, we check if files are '.rb'
  def pr_all_files_type(repo, pr_number, type)
    files = @client.pull_request_files(repo, pr_number)
    files.each do |file|
      @pr_files.push(file.filename) if file.filename.include? type
    end
  end

  # this function will check if the PR contains in comment the magic word
  # # for retrigger all the tests.
  def magicword(repo, pr_number, context)
    magic_word_trigger = "@gitbot rerun #{context} !!!"
    pr_comment = @client.issue_comments(repo, pr_number)
    # a pr contain always a comments, cannot be nil
    pr_comment.each do |com|
      # FIXME: if user in @org retrigger only
      # add org variable somewhere, maybe as option
      # next unless @client.organization_member?(@org, com.user.login)
      # delete comment otherwise it will be retrigger infinetely
      if com.body.include? magic_word_trigger
        @client.delete_comment(repo, com.id)
        return true
      end
    end
    false
  end

  # this function setup first pending to PR, then execute the tests
  # then set the status according to the results of script executed.
  # pr_head = is the PR branch
  # base = is a the upstream branch, where the pr targets
  def launch_test_and_setup_status(repo, pr)
    # pending
    @client.create_status(repo, pr.head.sha, 'pending',
                          context: @context, description: @description,
                          target_url: @target_url)
    # do tests
    @j_status = gbexec.pr_test(pr)
    # set status
    @client.create_status(repo, pr.head.sha, @j_status,
                          context: @context, description: @description,
                          target_url: @target_url)
  end

  # this function check if changelog specific test is active.
  def changelog_active(pr, comm_st)
    return false unless @changelog_test
    return false unless changelog_changed(@repo, pr, comm_st)
    true
  end

  def unreviewed_pr_test(pr, comm_st)
    return unless unreviewed_pr_ck(comm_st)
    pr_all_files_type(@repo, pr.number, @file_type)
    return if empty_files_changed_by_pr
    # gb.check is true when there is a job running as scheduler
    # which doesn't execute the test but trigger another job
    return false if @check
    launch_test_and_setup_status(@repo, pr)
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

  # check if the commit of a pr is on pending
  def pending_pr(comm_st)
    # 2) pending
    pending_on_context = false
    (0..comm_st.statuses.size - 1).each do |pr_status|
      if comm_st.statuses[pr_status]['context'] == @context &&
         comm_st.statuses[pr_status]['state'] == 'pending'
        pending_on_context = true
      end
    end
    pending_on_context
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

  # check it the cm of pr contain the context from gitbot already
  def context_pr(cm_st)
    # 1) context_present == false  triggers test. >
    # this means  the PR is not with context tagged
    context_present = false
    (0..cm_st.statuses.size - 1).each do |pr_status|
      context_present = true if cm_st.statuses[pr_status]['context'] == @context
    end
    context_present
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
    status = false
    (0..comm_st.statuses.size - 1).each do |pr_status|
      if comm_st.statuses[pr_status]['context'] == @context &&
         comm_st.statuses[pr_status]['state'] == 'success'
        status = true
      end
    end
    status
  end

  def failed_status?(comm_st)
    status = false
    (0..comm_st.statuses.size - 1).each do |pr_status|
      if comm_st.statuses[pr_status]['context'] == @context &&
         comm_st.statuses[pr_status]['state'] == 'failure'
        status = true
      end
    end
    status
  end

  # control if the pr change add any files, specified
  # it can be also a dir
  def empty_files_changed_by_pr
    return if pr_files.any?
    puts "no files of type #{@file_type} found! skipping"
    true
  end

  def do_changelog_test(repo, pr)
    @j_status = 'failure'
    pr_all_files_type(repo, pr.number, @file_type)
    # if the pr contains changes on .changes file, test ok
    @j_status = 'success' if @pr_files.any?
    magic_comment(repo, pr.number)
    @client.create_status(repo, pr.head.sha, @j_status,
                          context: @context, description: @description,
                          target_url: @target_url)
    true
  end

  # do the changelog test and set status
  def changelog_changed(repo, pr, comm_st)
    return false unless @changelog_test
    # only execute 1 time, don"t run if test is failed, or ok
    return false if failed_status?(comm_st)
    return false if success_status?(comm_st)
    do_changelog_test(repo, pr)
  end

  def retrigger_needed?(pr)
    # we want redo sometimes tests
    return false unless magicword(@repo, pr.number, @context)
    # changelog trigger
    if @changelog_test
      do_changelog_test(@repo, pr)
      return false
    end
    pr_all_files_type(@repo, pr.number, @file_type)
    return false unless @pr_files.any?
    # if check is set, the comment in the trigger job will be del.
    # so setting it to pending, it will be remembered
    true
  end
end
