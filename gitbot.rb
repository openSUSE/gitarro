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
  gb.launch_test_and_setup_status(gb.repo, pr)
  exit 0
end

gb = GitbotBackend.new
prs = gb.client.pull_requests(gb.repo, state: 'open')
puts 'no Pull request OPEN on the REPO!' if prs.any? == false

prs.each do |pr|
  puts '=' * 30 + "\n" + "TITLE_PR: #{pr.title}, NR: #{pr.number}\n" + '=' * 30
 # this check the last commit state, catch for review or not reviewd status.
  comm_st = gb.client.status(gb.repo, pr.head.sha)
  # we run the test in 2 conditions:
  # 1) the context  is not set, test didnt run
  # 2) the pending status is set on commit, repeat always when pending set
  context_present = gb.context_pr(comm_st)
  pending_on_context = gb.pending_pr(comm_st)
  # retrigger if magic word found
  retrigger_check(gb, pr)
  # check if changelog test was enabled, 1 time only
  unless context_present
    gb.changelog_active(pr)
    break
  end
  # 0) do test for unreviewed pr
  gb.unreviewed_pr_ck(comm_st)
  break if gb.unreviewed_pr_test(pr)
  # check the conditions 1,2 and it they happens run_test
  if context_present == false || pending_on_context == true
    gb.pr_all_files_type(gb.repo, pr.number, gb.file_type)
    gb.changelog_active(pr)
    next unless gb.pr_files.any?
    exit 1 if gb.check
    gb.launch_test_and_setup_status(gb.repo, pr)
    break
  end
end
STDOUT.flush

# red balls for jenkins
exit 1 if gb.j_status == 'failure'
