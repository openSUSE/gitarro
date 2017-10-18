#! /usr/bin/ruby

require 'octokit'
require 'optparse'
require 'time'
require 'English'
require 'faraday-http-cache'
require_relative 'opt_parser'
require_relative 'git_op'
require 'active_support'

# this module perform basic operations
# on prs and contain helper functions
# that use octokit client for retrieving info
# about the PR or commit
module GitHubPrOperations
  # check if the commit of a pr is on pending
  def pending_pr?(comm_st)
    # 2) pending
    (0..comm_st.statuses.size - 1).any? do |pr_status|
      comm_st.statuses[pr_status]['context'] == @context &&
        comm_st.statuses[pr_status]['state'] == 'pending'
    end
  end

  # check it the cm of pr contain the context from gitarro already
  def context_present?(cm_st)
    # 1) context_present == false  triggers test. >
    # this means  the PR is not with context tagged
    (0..cm_st.statuses.size - 1).any? do |pr_status|
      cm_st.statuses[pr_status]['context'] == @context
    end
  end

  # if the pr has travis test and one custom, we will have 2 elements.
  # in this case, if the 1st element doesn't have the state property
  # state property is "pending", failure etc.
  # if we don't have this, so we have 0 status
  # the PRs is "unreviewed"
  def commit_is_unreviewed?(comm_st)
    puts comm_st.statuses[0]['state']
    return false
  rescue NoMethodError
    return true
  end

  def success_status?(comm_st)
    (0..comm_st.statuses.size - 1).any? do |pr_status|
      comm_st.statuses[pr_status]['context'] == @context &&
        comm_st.statuses[pr_status]['state'] == 'success'
    end
  end

  def failed_status?(comm_st)
    (0..comm_st.statuses.size - 1).any? do |pr_status|
      comm_st.statuses[pr_status]['context'] == @context &&
        comm_st.statuses[pr_status]['state'] == 'failure'
    end
  end

  # Create a status for a PR
  def create_status(pr, status)
    client.create_status(@repo, pr.head.sha, status, context: @context,
                                                     description: @description,
                                                     target_url: @target_url)
  end

  # Return true if the PR was updated in less than the value of variable sec
  # or if sec < 0 (the check was disabled)
  # GitHub considers a PR updated when there is a new commit or a new comment
  def pr_last_update_less_than(pr, sec)
    Time.now.utc - pr.updated_at < sec || sec < 0 ? true : false
  end
end

# by default enabled (faraday_cache in memory, will be deleted
# after gitarro run 2nd time. usefull for -C check option
# and performance, since we cache)
module CachingOctokit
  def create_dir_store(cache_path)
    cache_name = 'httpcache'
    full_cache_dir = "#{cache_path}/#{cache_name}"
    ActiveSupport::Cache::FileStore.new(full_cache_dir)
  end

  def generate_cache(httpcache_path)
    # changed_since cannot work with cache
    return false unless generate_cache?
    stack = Faraday::RackBuilder.new do |builder|
      builder.use Faraday::HttpCache,
                  store: create_dir_store(httpcache_path),
                  serializer: Marshal,
                  shared_cache: false
      builder.use Octokit::Response::RaiseError
      builder.adapter Faraday.default_adapter
    end
    Octokit.middleware = stack
  end

  # if true we dont need the cache
  def generate_cache?
    @cachehttp
  end
end

# this module have helper methods for changelog tests
# it will be removed soon, but it helps to extract all
# changelog code from backend class
module ChangelogTests
  def magic_comment?(pr_num)
    @client.issue_comments(@repo, pr_num).any? do |com|
      com.body.include?('no changelog needed!')
    end
  end

  def do_changelog_test(pr)
    # if the pr contains changes on .changes file, test ok
    test_status = 'failure'
    test_status = 'success' if pr_all_files_type(pr.number, @file_type).any?
    test_status = 'success' if magic_comment?(pr.number)
    create_status(pr, test_status)
    test_status
  end

  # do the changelog test and set status
  def changelog_changed?(pr, comm_st)
    return false unless @changelog_test
    # only execute 1 time, don"t run if test is failed, or ok
    return false if failed_status?(comm_st) || success_status?(comm_st)
    do_changelog_test(pr)
  end
end

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
    git = GitOp.new(@git_dir, pr, @options)
    # merge PR-branch to upstream branch
    git.merge_pr_totarget(pr.base.ref, pr.head.ref)
    # export variables
    export_pr_variables(pr)
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

  def export_pr_variables(pr)
    ENV['GITARRO_PR_AUTHOR'] = pr.head.user.login.to_s
    ENV['GITARRO_PR_TITLE'] = pr.title.to_s
    ENV['GITARRO_PR_NUMBER'] = pr.number.to_s
    ENV['GITARRO_PR_TARGET_REPO'] = @repo
  end

  def script_exists?(script)
    n_exist = "\'#{script}\' doesn't exists.Enter valid file, -t option"
    raise n_exist if File.file?(script) == false
  end
end

# this the main public class is the backend of gitarro,
# were we execute the tests and so on
class Backend
  attr_accessor :options, :client, :gbexec
  # changelog tests module ( FIXME  remove this once changelog
  # tests are gone from backend and run separately
  include CachingOctokit
  include ChangelogTests
  include GitHubPrOperations

  # public method of backend
  def initialize(option = nil)
    @options = option.nil? ? OptParser.new.cmdline_options : option
    # each options will generate a object variable dinamically
    @options.each do |key, value|
      instance_variable_set("@#{key}", value)
      self.class.send(:attr_accessor, key)
    end
    # if changed_since option on, dont generate cache.
    generate_cache(@cachehttp)
    Octokit.auto_paginate = true
    @client = Octokit::Client.new(netrc: true)
    @gbexec = TestExecutor.new(@options)
  end

  # public method for get prs opened and matching the changed_since
  # condition
  def open_newer_prs
    prs = @client.pull_requests(@repo, state: 'open').select do |pr|
      pr_last_update_less_than(pr, @options[:changed_since])
    end
    print_pr_resume(prs)
    prs
  end

  # public for retrigger the test
  def retrigger_check(pr)
    return unless retrigger_needed?(pr)
    create_status(pr, 'pending')
    print_test_required
    exit 0 if @check
    launch_test_and_setup_status(pr) == 'success' ? exit(0) : exit(1)
  end

  # public always rerun tests against the pr number if this exists
  def triggered_by_pr_number?(pr)
    return false if @pr_number.nil? || @pr_number != pr.number
    puts "Got triggered by PR_NUMBER OPTION, rerunning on #{@pr_number}"
    print_test_required
    launch_test_and_setup_status(pr)
  end

  # FIXME: remove this pub. method once changelog test are separated
  # public method, trigger changelogtest if option active
  def changelog_active?(pr, comm_st)
    return false unless @changelog_test
    return false unless changelog_changed?(pr, comm_st)
    true
  end

  def unreviewed_new_pr?(pr, comm_st)
    return unless commit_is_unreviewed?(comm_st)
    pr_all_files_type(pr.number, @file_type)
    return if empty_files_changed_by_pr?(pr)
    # gb.check is true when there is a job running as scheduler
    # which doesn't execute the test but trigger another job
    print_test_required
    return false if @check
    launch_test_and_setup_status(pr)
  end

  def reviewed_pr?(comm_st, pr)
    # if PR status is not on pending and the context is not set,
    #  we dont run the tests
    return false unless context_present?(comm_st) == false ||
                        pending_pr?(comm_st)
    return true if changelog_active?(pr, comm_st)
    return false unless pr_all_files_type(pr.number, @file_type).any?
    print_test_required
    exit(0) if @check
    launch_test_and_setup_status(pr)
  end

  # this function will check if the PR contains in comment the magic word
  # # for retrigger all the tests.
  def retriggered_by_comment?(pr_number, context)
    magic_word_trigger = "gitarro rerun #{context} !!!"
    # a pr contain always a comments, cannot be nil
    @client.issue_comments(@repo, pr_number).each do |com|
      # delete comment otherwise it will be retrigger infinetely
      if com.body.include? magic_word_trigger
        @client.delete_comment(@repo, com.id)
        return true
      end
    end
    false
  end

  private

  # Show a message stating if there are opened PRs or not
  def print_pr_resume(prs)
    if prs.any?
      puts "[PRS=#{prs.any?}] PRs opened. Analyzing them..."
      return
    end
    if @options[:changed_since] >= 0
      puts "[PRS=#{prs.any?}] No Pull Requests opened or with changes " \
           "newer than #{options[:changed_since]} seconds"
    else
      puts "[PRS=#{prs.any?}] No Pull Requests opened"
    end
  end

  def print_test_required
    puts '[TESTREQUIRED=true] PR requires test'
  end

  # this function setup first pending to PR, then execute the tests
  # then set the status according to the results of script executed.
  # pr_head = is the PR branch
  # base = is a the upstream branch, where the pr targets
  # it return a string 'success', 'failure' (github status)
  def launch_test_and_setup_status(pr)
    # pending
    create_status(pr, 'pending')
    # do tests
    test_status = gbexec.pr_test(pr)
    # set status
    create_status(pr, test_status)
    # return status for other functions
    test_status
  end

  # check all files of a Prs Number if they are a specific type
  # EX: Pr 56, we check if files are '.rb'
  def pr_all_files_type(pr_number, type)
    filter_files_by_type(@client.pull_request_files(@repo, pr_number), type)
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

  # control if the pr change add any files, specified
  # it can be also a dir
  def empty_files_changed_by_pr?(pr)
    pr_all_files_type(pr.number, @file_type).any?
  end

  def retrigger_needed?(pr)
    # we want redo sometimes tests
    return false unless retriggered_by_comment?(pr.number, @context)
    # changelog trigger
    if @changelog_test
      do_changelog_test(pr)
      return false
    end
    # if check is set, the comment in the trigger job will be del.
    # so setting it to pending, it will be remembered
    pr_all_files_type(pr.number, @file_type).any?
  end
end
