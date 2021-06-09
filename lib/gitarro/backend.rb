#! /usr/bin/ruby

require 'json'
require 'octokit'
require 'optparse'
require 'time'
require 'English'
require_relative 'opt_parser'
require_relative 'git_op'

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

# This is a private class, which has the task to execute/run tests
# called by Backend
class TestExecutor
  def initialize(options)
    @options = options
    @options.each do |key, value|
      instance_variable_set("@#{key}", value)
      self.class.send(:attr_accessor, key)
    end
    Octokit.auto_paginate = true
    @client = Octokit::Client.new(netrc: true)
  end

  # this will clone the repo and execute the tests
  def pr_test(pr)
    clone_repo(@noshallow, pr)
    # do valid tests and return the result
    run_script
  end

  # run validation script for validating the PR.
  def run_script
    puts `#{@test_file}`
    $CHILD_STATUS.exitstatus.nonzero? ? 'failure' : 'success'
  end

  def export_pr_data(pr)
      export_pr_variables(pr)
      export_pr_data_to_simple_file(pr)
      export_pr_data_to_json_file(pr)
  end

  private

  def export_pr_data_to_simple_file(pr)
    # save this file in local dir where gitarro is executed.
    # This part is kept for compatibility purposes
    File.open('.gitarro_vars', 'w') do |file|
       file.write("GITARRO_PR_AUTHOR: #{pr.head.user.login}\n" \
       "GITARRO_PR_TITLE:  #{pr.title}\n" \
       "GITARRO_PR_NUMBER: #{pr.number}\n" \
       "GITARRO_PR_TARGET_REPO: #{@repo}\n")
    end
  end

  def export_pr_data_to_json_file(pr)
    pr = pr.to_hash
    pr[:files] = @client.pull_request_files(@repo, pr[:number]).map(&:to_h)
    File.open('.gitarro_pr.json', 'w') do |file|
       file.write(JSON.generate(pr))
    end
  end

  def export_pr_variables(pr)
    ENV['GITARRO_PR_AUTHOR'] = pr.head.user.login.to_s
    ENV['GITARRO_PR_TITLE'] = pr.title.to_s
    ENV['GITARRO_PR_NUMBER'] = pr.number.to_s
    ENV['GITARRO_PR_TARGET_REPO'] = @repo
  end

  def clone_repo(noshallow, pr)
    shallow = GitShallowClone.new(@git_dir, pr, @options)
    # by default we use always shallow clone
    unless noshallow
      shallow.clone
      return
    end
    # this is for using the merging to ref
    full_clone(pr)
  end

  def full_clone(pr)
    git = GitOp.new(@git_dir, pr, @options)
    git.merge_pr_totarget(pr.base.ref, pr.head.ref)
    git.del_pr_branch(pr.base.ref, pr.head.ref)
  end
end

# this the main public class is the backend of gitarro,
# were we execute the tests and so on
class Backend
  attr_accessor :options
  attr_reader :gbexec, :client
  include GitHubPrOperations

  # public method of backend
  def initialize(option = nil)
    @options = option.nil? ? OptParser.new.cmdline_options : option
    # each options will generate a object variable dinamically
    @options.each do |key, value|
      instance_variable_set("@#{key}", value)
      self.class.send(:attr_accessor, key)
    end
    Octokit.auto_paginate = true
    @client = Octokit::Client.new(netrc: true)
    @gbexec = TestExecutor.new(@options)
  end

  # public method retrieve pull request to process
  def required_prs
    return open_newer_prs if @options[:pr_number].nil?

    [@client.pull_request(@repo, @options[:pr_number])]
  end

  # public method for check if pr belong to user specified branch
  # if the pr belong to the branch continue tests
  # otherwise just skip tests without setting any status
  def pr_equal_specific_branch?(pr)
     return true if @branch.nil?
     return true if @branch == pr.base.ref 

     puts "branch \"#{pr.base.ref}\" should match github-branch \"#{@branch}\" (given) !!!"
     puts 'skipping tests !!!'
     false
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

  # public forcing to run the test
  def force_run_test(pr)
    return false unless @force_test && defined?(@pr_number)

    print_test_required
    gbexec.export_pr_data(pr)
    launch_test_and_setup_status(pr)
  end

  # public for retrigger the test
  def retrigger_check(pr)
    return false unless retrigger_needed?(pr)

    print_test_required
    gbexec.export_pr_data(pr)
    exit 0 if @check
    launch_test_and_setup_status(pr)
  end

  # public tests against the pr number passed by parameter
  def triggered_by_pr_number?
    return false if @pr_number.nil?

    # Note that the test will only run if it pass the checks on unreviewed_new_pr
    pr_on_number = @client.pull_request(@repo, @pr_number)
    puts "Got triggered by PR_NUMBER OPTION, PR: #{@pr_number}"
    comm_st = @client.status(@repo, pr_on_number.head.sha)
    unreviewed_new_pr?(pr_on_number, comm_st)
  end

  def unreviewed_new_pr?(pr, comm_st)
    return unless commit_is_unreviewed?(comm_st)

    return true if empty_files_changed_by_pr?(pr)

    # gb.check is true when there is a job running as scheduler
    # which doesn't execute the test but trigger another job
    print_test_required
    gbexec.export_pr_data(pr)
    return false if @check

    launch_test_and_setup_status(pr)
  end

  def reviewed_pr?(comm_st, pr)
    # if PR status is not on pending and the context is not set,
    #  we dont run the tests
    return false unless context_present?(comm_st) == false ||
                        pending_pr?(comm_st)
    return false unless pr_all_files_type(pr.number, @file_type).any?

    print_test_required
    gbexec.export_pr_data(pr)
    exit(0) if @check
    launch_test_and_setup_status(pr)
  end

  # this function will check if the PR contains in comment the magic word
  # # for retrigger all the tests.
  def retriggered_by_comment?(pr, context)
    magic_word_trigger = "gitarro rerun #{context} !!!"
    # a pr contain always a comments, cannot be nil
    @client.issue_comments(@repo, pr.number).each do |com|
      # delete comment otherwise it will be retrigger infinetely
      next unless com.body.include? magic_word_trigger

      puts "Re-run test \"#{context}\""
      @client.delete_comment(@repo, com.id)
      return true
    end
    false
  end

  # this function will check if the PR contains a checkbox
  # for retrigger all the tests.
  def retriggered_by_checkbox?(pr, context)
    return false unless pr.body.match(/\[x\]\s+Re-run\s+test\s+"#{context}"/i)

    skipped = ''
    unless empty_files_changed_by_pr?(pr)
      skipped = '(Test skipped, there are no changes to test)'
    end

    puts "Re-run test \"#{context}\" #{skipped}"
    new_pr_body = pr.body.gsub("[x] Re-run test \"#{context}\"",
                               "[ ] Re-run test \"#{context}\" #{skipped}")
    new_pr_body = new_pr_body.gsub("#{skipped} #{skipped}", skipped) unless skipped.empty?
                    
    @client.update_pull_request(@repo, pr.number, body: new_pr_body)
    true
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
    test_status == 'success' ? exit(0) : exit(1)
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
    puts "DEBUG!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! eoeoeoeoe\n"
    puts "DEBUG: files #{files}"
    puts "DEBUG: type #{type}"
    files.each do |f|
      puts "filename #{f.filename}"
      puts "contents_url #{f.contents_url}"
    end
    ff = []
    if type == 'notype'
      ff = files
    else
      files.each do |f|
        if f.filename.include? type
          ff.push(f.filename)
          puts "DEBUG: YEAHHHHHHHH filename #{f.filename} includes type #{type}!!!"
        end
      end
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
    return false unless retriggered_by_checkbox?(pr, @context) ||
                        retriggered_by_comment?(pr, @context)

    # if check is set, the comment in the trigger job will be del.
    # so setting it to pending, it will be remembered
    empty_files_changed_by_pr?(pr)
  end
end
