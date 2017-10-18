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
  git_workspace = '/tmp/foo3'
  @test = GitarroTestingCmdLine.new(@gitarrorepo, git_workspace)
  # commit status
  @comm_st = @rgit.commit_status(@pr)
end

# secondary --changed_since
describe 'cmdline changed-since' do
  before(:each) do
    init_tests_setup(GIT_REPO)
  end

  describe '.changed_since_not_present' do
    it 'gitarro should see PR when --change_since not present' do
      context = 'changed-since-not-present'
      comment = @rgit.create_comment(@pr, "gitarro rerun #{context} !!!")
      result, output = @test.changed_since(@comm_st, -1, context)
      @rgit.delete_c(comment.id)
      expect(result).to be true
      expect(output).to match(/^\[PRS=true\].*/)
    end
  end

  describe '.changed_since_60' do
    it 'gitarro should see PR hanged in the last 60 seconds' do
      context = 'changed-since-60'
      comment = @rgit.create_comment(@pr, "gitarro rerun #{context} !!!")
      result, output = @test.changed_since(@comm_st, 60, context)
      @rgit.delete_c(comment.id)
      expect(result).to be true
      expect(output).to match(/^\[PRS=true\].*/)
    end
  end

  describe '.changed_since_zero' do
    it 'gitarro should not see any PRs' do
      context = 'changed-since-zero'
      comment = @rgit.create_comment(@pr, "gitarro rerun #{context} !!!")
      result, output = @test.changed_since(@comm_st, 0, context)
      @rgit.delete_c(comment.id)
      expect(result).to be true
      expect(output).to match(/^\[PRS=false\].*/)
    end
  end
end
