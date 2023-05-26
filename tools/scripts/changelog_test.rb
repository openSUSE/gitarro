#! /usr/bin/ruby

require 'octokit'

if ENV.key?('GITARRO_PR_TARGET_REPO')
  REPO = ENV['GITARRO_PR_TARGET_REPO']
else
  puts 'ERROR: Environment variable GITARRO_PR_TARGET_REPO not available'
  exit(1)
end

if ENV.key?('GITARRO_PR_NUMBER')
  PR_NUMBER = Integer(ENV['GITARRO_PR_NUMBER'])
else
  puts 'ERROR: Environment variable GITARRO_PR_NUMBER not available'
  exit(1)
end

# Warning: this script assume that octokit has access to netrc credentials.

# do changelog test for PRs
class ChangelogTests
  attr_reader :client, :pr_num, :repo

  def initialize(client, repo, pr_num)
    @client = client
    client.auto_paginate = true
    @pr_num = pr_num
    @repo = repo
  end

  def changelog_modified?
    files = @client.pull_request_files(repo, pr_num)
    puts("Files modified by PR ##{@pr_num}:")
    puts files.collect{|f| "  - #{f.filename}"}
    puts

    # First test if the master changelog files have been modified
    return false if master_chlog_modified?(files)

    # Return success if the bypass flags are set
    if magic_comment? || magic_checkbox?
      puts "Changelog test skipped by user."
      return true
    end

    # Return success if changelogs are added
    if changelog_added?(files)
      puts "Changelog test passed."
      return true
    end

    puts "No changelog entry found. Please add the required changelog entries."
    false
  end

  private

  def magic_comment?
    @client.issue_comments(repo, pr_num).any? do |com|
      com.body.include?('no changelog needed')
    end
  end

  def magic_checkbox?
    return false if pr_num.nil?

    pr = @client.pull_request(repo, pr_num)
    return true if pr.body.match(/\[x\]\s+No\s+changelog\s+needed/i)

    false
  end

  def master_chlog_modified?(files)
    # Master changelog files (*.changes) cannot be modified directly
    master_files = files.select{|f| f.filename.end_with? '.changes'}
    if not master_files.empty?
      puts "Master changelog files cannot be modified directly."
      puts "Please revert your changes on the following master changelog file(s):"
      puts master_files.collect{|f| "  - #{f.filename}"}
      return true
    end
    false
  end

  def changelog_added?(files)
    # Changelog filenames must be in the following format:
    # <packagename>.changes.<user>.<feature>
    files.any? { |f| f.filename.include? '.changes.' }
  end
end

def success_exit
  puts 'Changelog test passed.'
  exit(0)
end
client = Octokit::Client.new(netrc: true)
chlog = ChangelogTests.new(client, REPO, PR_NUMBER)

exit(0) if chlog.changelog_modified?
exit(1)
