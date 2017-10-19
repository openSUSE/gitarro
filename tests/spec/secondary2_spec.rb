#! /usr/bin/ruby

require_relative 'test_lib.rb'

# this small class is used for setup and run Rspec
# locally on forked repos
class SetupRspec
  def self.custom_git_repo
    git_repo = ENV['repo']
    no_repo = 'No gitarro repo was given! use your forked repo'
    raise ArgumentError, no_repo if git_repo.nil?
    git_repo
  end

  def self.pr_number
    number = ENV['pr_num']
    no_pr = 'No pr Number where to run tests was given'
    raise ArgumentError, no_pr if number.nil?
    number
  end
end
# setup testenv ( if needed)
GIT_REPO = SetupRspec.custom_git_repo
puts 'Using following github repo: ' + GIT_REPO
# this is used in only 2/3 tests
PR_NUMBER = SetupRspec.pr_number
puts 'Using pull_request number: ' + PR_NUMBER

# helper_functon
def init_tests_setup(git_repo)
  @gitarrorepo = git_repo
  @rgit = GitRemoteOperations.new(@gitarrorepo)
  @pr = @rgit.first_pr_open
  git_workspace = '/tmp/foo2'
  @test = GitarroTestingCmdLine.new(@gitarrorepo, git_workspace)
  # commit status
  @comm_st = @rgit.commit_status(@pr)
end

describe 'gitarro print when a PR requre test' do
  before(:each) do
    init_tests_setup(GIT_REPO)
  end

  describe '.pr_requiring_test' do
    it 'gitarro should see PR requiring test' do
      context = 'pr-should-retest'
      comment = @rgit.create_comment(@pr, "gitarro rerun #{context} !!!")
      result, output = @test.changed_since(@comm_st, 60, context)
      @rgit.delete_c(comment.id)
      expect(result).to be true
      expect(output).to match(/^\[TESTREQUIRED=true\].*/)
    end
  end

  describe '.pr_not_requiring_test' do
    it 'gitarro should see PR as not requiring test' do
      context = 'pr-should-not-retest'
      comment = @rgit.create_comment(@pr, "Updating PR for #{context} !!!")
      result, output = @test.changed_since(@comm_st, 60, context)
      @rgit.delete_c(comment.id)
      expect(result).to be true
      expect(output).not_to match(/^\[TESTREQUIRED=true\].*/)
    end
  end
end

# env variables
describe 'gitarro pass env. variable to scripts' do
  before(:each) do
    init_tests_setup(GIT_REPO)
  end

  describe '.env variable are read from script' do
    it 'Passing env variable to script, we can use them in script' do
      cont = 'env_test_script'
      rcomment = @rgit.create_comment(@pr, "gitarro rerun #{cont} !!!")
      stdout = @test.env_test(cont)
      gitarro_pr_number = @pr.number.to_s
      gitarro_pr_title = @pr.title.to_s
      gitarro_pr_author = @pr.head.user.login.to_s
      expect(stdout).to match("GITARRO_PR_NUMBER: #{gitarro_pr_number}")
      expect(stdout).to match("GITARRO_PR_TITLE: #{gitarro_pr_title}")
      expect(stdout).to match("GITARRO_PR_AUTHOR: #{gitarro_pr_author}")
      expect(stdout).to match("GITARRO_PR_TARGET_REPO: #{GIT_REPO}")
      @rgit.delete_c(rcomment.id)
    end
  end
end
