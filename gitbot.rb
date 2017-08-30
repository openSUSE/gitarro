#!/usr/bin/ruby

require 'English'
require 'octokit'
require 'optparse'
require_relative 'lib/opt_parser'
require_relative 'lib/git_op'
require_relative 'lib/gitbot_backend'

# fetch all open PRS
gb = GitbotBackend.new
prs = gb.client.pull_requests(gb.repo, state: 'open')
# exit if repo has no prs open
puts 'no Pull request OPEN on the REPO!' if prs.any? == false
prs.each do |pr|
  puts '=' * 30 + "\n" + "TITLE_PR: #{pr.title}, NR: #{pr.number}\n" + '=' * 30
  # this check the last commit state, catch for review or not reviewd status.
  commit_state = gb.client.status(gb.repo, pr.head.sha)
  begin
    # the first element of array a review-test.
    # if the pr has travis test and one custom, we will have 2 elements.
    # in this case, if the 1st element doesn't have the state property
    # state property is "pending", failure etc.
    # if we don't have this, the PRs is "unreviewed"
    puts commit_state.statuses[0]['state']
  rescue NoMethodError
    # in this situation we have no reviews-tests set at all.
    gb.check_for_all_files(gb.repo, pr.number, gb.file_type)
    if gb.changelog_test
      gb.check_if_changes_files_changed(gb.repo, pr)
      next
    elsif gb.pr_files.any? == false
      puts "no files of type #{gb.file_type} found! skipping"
      next
    else
      exit 1 if gb.check
      gb.launch_test_and_setup_status(gb.repo, pr.head.sha, pr.head.ref, pr.base.ref)
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
    if commit_state.statuses[pr_status]['context'] == gb.context &&
       commit_state.statuses[pr_status]['state'] == 'pending'
      pending_on_context = true
    end
  end
  # check the conditions 1,2 and it they happens run_test
  if context_present == false || pending_on_context == true
    gb.check_for_all_files(gb.repo, pr.number, gb.file_type)
    if gb.changelog_test
      gb.check_if_changes_files_changed(gb.repo, pr)
      next
    end
    next if gb.pr_files.any? == false
    exit 1 if gb.check
    gb.launch_test_and_setup_status(gb.repo, pr.head.sha, pr.head.ref, pr.base.ref)
    break
  end
  # we want redo sometimes tests
  next if gb.magicword(gb.repo, pr.number, gb.context) == false
  gb.check_for_all_files(gb.repo, pr.number, gb.file_type)
  next if gb.pr_files.any? == false
  puts 'Got retriggered by magic word'
  if gb.check
    # if check is set, the comment in the trigger job will be del.
    # so setting it to pending, it will be remembered
    gb.client.create_status(gb.repo, pr.head.sha, 'pending',
                            context: gb.context, description: gb.description,
                            target_url: gb.target_url)
    exit 1
  end
  gb.launch_test_and_setup_status(gb.repo, pr.head.sha, pr.head.ref, pr.base.ref)
  break
end

STDOUT.flush

# sleep timeout minutes to spare time from jenkins jobs
# if j_status is empty no code were executed.
if gb.j_status.nil? || gb.j_status.empty?
  unless gb.timeout.nil? || gb.timeout.zero?
    puts "\nNO new PRs found! going to sleep for #{gb.timeout} secs"
    STDOUT.flush
    sleep(gb.timeout)
  end
end
# jenkins
exit 1 if gb.j_status == 'failure'
