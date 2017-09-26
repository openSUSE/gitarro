#!/usr/bin/ruby

require 'English'
require 'octokit'
require 'optparse'
require_relative 'lib/opt_parser'
require_relative 'lib/git_op'
require_relative 'lib/gitbot_backend'

gb = GitbotBackend.new
prs = gb.open_prs

prs.each do |pr|
  puts '=' * 30 + "\n" + "TITLE_PR: #{pr.title}, NR: #{pr.number}\n" + '=' * 30
  # this check the last commit state, catch for review or not reviewd status.
  comm_st = gb.client.status(gb.repo, pr.head.sha)
  # pr number trigger.
  break if gb.trigger_by_pr_number(pr)
  # retrigger if magic word found
  gb.retrigger_check(pr)
  # check if changelog test was enabled
  break if gb.changelog_active(pr, comm_st)
  # 0) do test for unreviewed pr
  break if gb.unreviewed_pr_test(pr, comm_st)
  # we run the test in 2 conditions:
  # 1) the context  is not set, test didnt run
  # 2) the pending status is set on commit, repeat always when pending set
  # check the conditions 1,2 and it they happens run_test
  break if gb.reviewed_pr_test(comm_st, pr)
end
STDOUT.flush

# red balls for jenkins
exit 1 if gb.j_status == 'failure'
