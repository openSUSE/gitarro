#!/usr/bin/ruby

require 'English'
require 'octokit'
require 'optparse'
require_relative 'lib/opt_parser'
require_relative 'lib/git_op'

# run validation script for validating the PR.
def run_script
  f_not_exist_msg = "\'#{@test_file}\' doesn't exists.Enter valid file, -t option"
  raise f_not_exist_msg if File.file?(@test_file) == false
  out = `#{@test_file}`
  @j_status = 'failure' if $CHILD_STATUS.exitstatus.nonzero?
  @j_status = 'success' if $CHILD_STATUS.exitstatus.zero?
  puts out
end

# main function for doing the test
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

def check_if_changes_files_changed(repo, pr)
  if @changelog_test
    if @pr_files.any? == false
      @j_status = 'failure'
      pr_number = pr.number
      comments = @client.issue_comments(repo, pr_number)
      if ! comments.nil?
        comments.each do |com|
          if com.body.include?("no changelog needed!")
            @j_status = 'success'
            break
          end
        end
      end
    else
      @j_status = 'success'
    end
    @client.create_status(repo, pr.head.sha, @j_status,
                          context: @context, description: @description,
                          target_url: @target_url)
  end
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

@options = OptParser.gitbot_options
# git_dir is where we have the github repo in our machine
@git_dir = @options[:git_dir]
@pr_files = []
@file_type = @options[:file_type]
repo = @options[:repo]
@context = @options[:context]
@description = @options[:description]
@test_file = @options[:test_file]
@changelog_test = @options[:changelog_test]
@timeout = @options[:timeout]
# optional, this url will be appended on github page.(usually a jenkins)
@target_url = @options[:target_url]
@check = @options[:check]
Octokit.auto_paginate = true
@client = Octokit::Client.new(netrc: true)
@j_status = ''
# FIXME: remove hardcode and add an option param for organisation.
@org = 'SUSE'
# fetch all open PRS
prs = @client.pull_requests(repo, state: 'open')
# exit if repo has no prs open
puts 'no Pull request OPEN on the REPO!' if prs.any? == false
prs.each do |pr|
  puts '=' * 30 + "\n" + "TITLE_PR: #{pr.title}, NR: #{pr.number}\n" + '=' * 30
  # this check the last commit state, catch for review or not reviewd status.
  commit_state = @client.status(repo, pr.head.sha)
  begin
    # the first element of array a review-test. 
    # if the pr has travis test and one custom, we will have 2 elements.
    # in this case, if the 1st element doesn't have the state property
    # state property is "pending", failure etc. 
    # if we don't have this, the PRs is "unreviewed"
    puts commit_state.statuses[0]['state']
  rescue NoMethodError
    # in this situation we have no reviews-tests set at all.
    check_for_all_files(repo, pr.number, @file_type)
    if @changelog_test
      check_if_changes_files_changed(repo, pr)
      next
    elsif @pr_files.any? == false
      puts "no files of type #{@file_type} found! skipping"
      next
    else
      exit 1 if @check
      launch_test_and_setup_status(repo, pr.head.sha, pr.head.ref, pr.base.ref)
      break
    end
  end
  puts '*' * 30 + "\nPR is already reviewed by bot \n" + '*' * 30 + "\n"
  # we run the test in 2 conditions:
  # 1) the context "pylint-test" is not set, so we are in a situation
  # like we have already 3 tests runned against a pr, but not the current one.
  # 2) is like 1 but is when something went wrong and the pending status
  # was set, but the bot exited or was buggy, we want to rerun the test.
  # pending status is not a good status, always have only ok or fail status.
  # and repeat the test for the pending

  # 1) context_present == false  triggers test. >
  # this means  the PR is not with context tagged
  context_present = false
  for pr_status in (0..commit_state.statuses.size - 1) do
    context_present = true if commit_state.statuses[pr_status]['context'] == @context
  end
  # 2) pending
  pending_on_context = false
  for pr_status in (0..commit_state.statuses.size - 1) do
    if commit_state.statuses[pr_status]['context'] == @context &&
       commit_state.statuses[pr_status]['state'] == 'pending'
      pending_on_context = true
    end
  end
  # check the conditions 1,2 and it they happens run_test
  if context_present == false || pending_on_context == true
    check_for_all_files(repo, pr.number, @file_type)
    if @changelog_test
      check_if_changes_files_changed(repo, pr)
      next
    end
    next if @pr_files.any? == false
    exit 1 if @check
    launch_test_and_setup_status(repo, pr.head.sha, pr.head.ref, pr.base.ref)
    break
  end
  # we want redo sometimes test
  next if magicword(repo, pr.number, @context) == false
  check_for_all_files(repo, pr.number, @file_type)
  next if @pr_files.any? == false
  puts 'Got retriggered by magic word'
  exit 1 if @check
  launch_test_and_setup_status(repo, pr.head.sha, pr.head.ref, pr.base.ref)
  break
end

STDOUT.flush

# sleep timeout minutes to spare time from jenkins jobs
# if j_status is empty no code were executed.
if @j_status.nil? || @j_status.empty?
  unless @timeout.nil? || @timeout.zero?
    puts "\nNO new PRs found! going to sleep for #{@timeout} secs"
    STDOUT.flush
    sleep(@timeout)
  end
end
# jenkins
exit 1 if @j_status == 'failure'
