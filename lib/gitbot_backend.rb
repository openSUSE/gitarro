#! /usr/bin/ruby

require 'octokit'
require 'optparse'
require 'English'
require_relative 'opt_parser'
require_relative 'git_op'

# this class is the backend of gitbot, were we execute the tests and so on
class GitbotBackend
  attr_accessor :j_status, :options, :client, :pr_files
  # public method of backend
  def initialize
    Octokit.auto_paginate = true
    @client = Octokit::Client.new(netrc: true)
    @options = OptParser.gitbot_options
    @j_status = ''
    @pr_files = []
    # each options will generate a object variable dinamically
    @options.each do |key, value|
      instance_variable_set("@#{key}", value)
      self.class.send(:attr_accessor, key)
    end
  end

  # run validation script for validating the PR.
  def run_script
    n_exist = "\'#{@test_file}\' doesn't exists.Enter valid file, -t option"
    raise n_exist if File.file?(@test_file) == false

    out = `#{@test_file}`
    @j_status = 'failure' if $CHILD_STATUS.exitstatus.nonzero?
    @j_status = 'success' if $CHILD_STATUS.exitstatus.zero?
    puts out
  end # main function for doing the test

  def pr_test(upstream, pr_sha_com, repo, pr_branch, pr)
    git = GitOp.new(@git_dir, pr)
    # get author:
    pr_com = @client.commit(repo, pr_sha_com)
    _author_pr = pr_com.author.login
    # merge PR-branch to upstream branch
    git.merge_pr_totarget(upstream, pr_branch, repo)
    # do valid tests
    run_script
    # del branch
    git.del_pr_branch(upstream, pr_branch)
  end

  # if the Pr contains magic word, test changelog
  # is true
  def magic_comment(repo, pr_num)
    comments = @client.issue_comments(repo, pr_num)
    comments.each do |com|
      if com.body.include?('no changelog needed!')
        @j_status = 'success'
        break
      end
    end
  end

  # do the changelog test and set status
  def changelog_changed(repo, pr)
    return unless @changelog_test
    @j_status = 'failure'
    pr_all_files_type(repo, pr.number, @file_type)
    # if the pr contains changes on .changes file, test ok
    @j_status = 'success' if @pr_files.any?
    magic_comment(repo, pr.number)
    @client.create_status(repo, pr.head.sha, @j_status,
                          context: @context, description: @description,
                          target_url: @target_url)
  end

  # check all files of a Prs Number if they are a specific type
  # EX: Pr 56, we check if files are '.rb'
  def pr_all_files_type(repo, pr_number, type)
    files = @client.pull_request_files(repo, pr_number)
    files.each do |file|
      @pr_files.push(file.filename) if file.filename.include? type
    end
  end

  def create_comment(repo, pr, comment)
    @client.create_commit_comment(repo, pr, comment)
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
  def launch_test_and_setup_status(repo, pr_head_sha, pr_head_ref, pr_base_ref, pr)
    # pending
    @client.create_status(repo, pr_head_sha, 'pending',
                          context: @context, description: @description,
                          target_url: @target_url)
    # do tests
    pr_test(pr_base_ref, pr_head_sha, repo, pr_head_ref, pr)
    # set status
    @client.create_status(repo, pr_head_sha, @j_status,
                          context: @context, description: @description,
                          target_url: @target_url)
  end

  def retrigger_test(pr)
    # we want redo sometimes tests
    return false unless magicword(@repo, pr.number, @context)
    pr_all_files_type(@repo, pr.number, @file_type)
    return false unless @pr_files.any?
    # if check is set, the comment in the trigger job will be del.
    # so setting it to pending, it will be remembered
    true
  end

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

  # this function check if changelog specific test is active.
  def changelog_active(pr)
    return unless changelog_test
    changelog_changed(@repo, pr)
    true
  end

  # control if the pr change add any files, specified
  # it can be also a dir
  def empty_files_changed_by_pr
    return if pr_files.any?
    puts "no files of type #{@file_type} found! skipping"
    true
  end

  # the first element of array a review-test.
  # if the pr has travis test and one custom, we will have 2 elements.
  # in this case, if the 1st element doesn't have the state property
  # state property is "pending", failure etc.
  # if we don't have this, the PRs is "unreviewed"
  def unreviewed_pr_ck(comm_st)
    puts comm_st.statuses[0]['state']
    @unreviewed_pr = false
  rescue NoMethodError
    @unreviewed_pr = true
    # in this situation we have no reviews-tests set at all.
  end

  def unreviewed_pr_test(pr)
    return unless @unreviewed_pr
    pr_all_files_type(@repo, pr.number, @file_type)
    return if empty_files_changed_by_pr
    # gb.check is true when there is a job running as scheduler
    # which doesn't execute the test but trigger another job
    return false if @check
    launch_test_and_setup_status(@repo, pr.head.sha,
                                 pr.head.ref, pr.base.ref, pr)
    true
  end
  public :retrigger_test, :launch_test_and_setup_status, :changelog_active, :unreviewed_pr_test
end
