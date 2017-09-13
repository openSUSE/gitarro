#!/usr/bin/ruby

require 'English'
require 'octokit'
require 'optparse'
require_relative 'lib/opt_parser'
require_relative 'lib/git_op'
require_relative 'lib/gitbot_backend'

def retrigger_check(gb, pr)
  return true unless gb.retrigger_test(pr)
  gb.client.create_status(gb.repo, pr.head.sha, 'pending',
                          context: gb.context, description: gb.description,
                          target_url: gb.target_url)
  exit 1 if gb.check
  gb.launch_test_and_setup_status(gb.repo, pr.head.sha,
                                  pr.head.ref, pr.base.ref)
  exit 0
end


gb = GitbotBackend.new
prs = gb.client.pull_requests(gb.repo, state: 'open')
# exit if repo has no prs open
puts 'no Pull request OPEN on the REPO!' if prs.any? == false

prs.each do |pr|
  puts '=' * 30 + "\n" + "TITLE_PR: #{pr.title}, NR: #{pr.number}\n" + '=' * 30
  # this check the last commit state, catch for review or not reviewd status.
  comm_st = gb.client.status(gb.repo, pr.head.sha)
  # retrigger if magic word found
  retrigger_check(gb, pr)
  # check if changelog test was enabled
  next if gb.changelog_active(pr)
  gb.unreviewed_pr_ck(comm_st)
  # 0) do test for unreviewed pr
  next if gb.unreviewed_pr_test(pr)
  # skip iteration if we did the test for the pr
  # we run the test in 2 conditions:
  # 1) the context "pylint-test" is not set, so we are in a situation
  # like we have already 3 tests runned against a pr, but not the current one.
  # 2) is like 1 but is when something went wrong and the pending status
  # was set, but the bot exited or was buggy, we want to rerun the test.
  # pending status is not a good status, always have only ok or fail status.
  # and repeat the test for the pending
  context_present = gb.context_pr(comm_st)
  pending_on_context = gb.pending_pr(comm_st)
  # check the conditions 1,2 and it they happens run_test
  if context_present == false || pending_on_context == true
    gb.pr_all_files_type(gb.repo, pr.number, gb.file_type)
    gb.changelog_active(pr)
    next unless gb.pr_files.any?
    exit 1 if gb.check
    gb.launch_test_and_setup_status(gb.repo, pr.head.sha,
                                    pr.head.ref, pr.base.ref)
    break
  end
end
STDOUT.flush

# red balls for jenkins
exit 1 if gb.j_status == 'failure'
