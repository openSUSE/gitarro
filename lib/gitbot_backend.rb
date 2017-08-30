#! /usr/bin/ruby

require 'octokit'
require 'optparse'
require 'English'
require_relative 'opt_parser'
require_relative 'git_op'

# this class is the backend of gitbot, were we execute the tests and so on
class GitbotBackend
  attr_accessor :j_status, :options, :client, :pr_files
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

  def pr_test(upstream, pr_sha_com, repo, pr_branch)
    git = GitOp.new(@git_dir)
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

  def ck_comments(repo, pr_num)
    comments = @client.issue_comments(repo, pr_num)
    comments.each do |com|
      if com.body.include?('no changelog needed!')
        @j_status = 'success'
        break
      end
    end
  end

  def check_if_changes_files_changed(repo, pr)
    return unless @changelog_test
    @j_status = 'success'
    # GuardClause
    return if @pr_files.any?
    @j_status = 'failure'
    ck_comments(repo, pr.number)
    @client.create_status(repo, pr.head.sha, @j_status,
                          context: @context, description: @description,
                          target_url: @target_url)
  end

  # check all files of a Prs Number if they are a specific type
  # EX: Pr 56, we check if files are '.rb'
  def check_for_all_files(repo, pr_number, type)
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
      # if user in @org retrigger only
      next unless @client.organization_member?(@org, com.user.login)
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
  def launch_test_and_setup_status(repo, pr_head_sha, pr_head_ref, pr_base_ref)
    # pending
    @client.create_status(repo, pr_head_sha, 'pending',
                          context: @context, description: @description,
                          target_url: @target_url)
    # do tests
    pr_test(pr_base_ref, pr_head_sha, repo, pr_head_ref)
    # set status
    @client.create_status(repo, pr_head_sha, @j_status,
                          context: @context, description: @description,
                          target_url: @target_url)
  end
  # *********************************************
end
