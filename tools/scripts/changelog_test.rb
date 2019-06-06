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
    @pr_num = pr_num
    @repo = repo
  end

  def changelog_modified?
    # if the pr contains changes on .changes file, test ok
    return true if pr_contains_changelog? || magic_checkbox? || magic_comment?

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
    return true unless pr.body.match(/\[x\]\s+No\s+changelog\s+needed/i)

    false
  end

  def pr_contains_changelog?
    pr_file_have_changelog?(@client.pull_request_files(repo, pr_num))
  end

  def pr_file_have_changelog?(files)
    # .changes file is where we track changelog entries.
    files.any? { |f| f.filename.include? '.changes' }
  end
end

def success_exit
  puts 'CHANGELOG TEST WAS OK!!!'
  exit(0)
end
client = Octokit::Client.new(netrc: true)
chlog = ChangelogTests.new(client, REPO, PR_NUMBER)

# if true we exit with 0, so the test is sucessefull. otherwise the test fail.

success_exit if chlog.changelog_modified?
puts
puts 'CHANGELOG TESTS FAILED UPDATE YOUR .changes file in the PR!!'
exit(1)
