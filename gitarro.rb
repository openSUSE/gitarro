#!/usr/bin/ruby

require 'English'
require 'octokit'
require 'optparse'
require_relative 'lib/gitarro/opt_parser'
require_relative 'lib/gitarro/git_op'
require_relative 'lib/gitarro/backend'

b = Backend.new
prs = b.open_newer_prs
exit 0 if prs.empty?

if b.options[:basiccheck]
  prs.each do |pr|
    comm_st = b.client.status(b.repo, pr.head.sha)
    if silenced do b.commit_is_unreviewed?(comm_st) || b.retriggered_by_checkbox?(pr, 'all') end
      puts "PR #{pr.number} has a pending test."
      b.print_test_required
      break
    end
  end
  exit 0
end

prs.each do |pr|
  puts '=' * 30 + "\n" + "TITLE_PR: #{pr.title}, NR: #{pr.number}\n" + '=' * 30
  # check if prs contains the branch given otherwise just break
  next unless b.pr_equal_spefic_branch?(pr)

  # this check the last commit state, catch for review or not reviewd status.
  comm_st = b.client.status(b.repo, pr.head.sha)
  # pr number trigger.
  #TODO: Why we are doing another request to get the PR if we can pass it by parameter?
  break if b.triggered_by_pr_number?

  # retrigger if magic word found
  b.retrigger_check(pr)
  # 0) do test for unreviewed pr
  break if b.unreviewed_new_pr?(pr, comm_st)
  # we run the test in 2 conditions:
  # 1) the context  is not set, test didnt run
  # 2) the pending status is set on commit, repeat always when pending set
  # check the conditions 1,2 and it they happens run_test
  break if b.reviewed_pr?(comm_st, pr)
end
STDOUT.flush