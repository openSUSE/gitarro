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

# do tests
describe 'cmdline foundamental' do
  before(:each) do
    @gitarrorepo = GIT_REPO
    @rgit = GitRemoteOperations.new(@gitarrorepo)
    @pr = @rgit.first_pr_open
    @test = GitarroTestingCmdLine.new(@gitarrorepo)
    # commit status
    @comm_st = @rgit.commit_status(@pr)
  end

  describe '.basic' do
    it 'gitarro run on fixed pr_number with basic options, cmdline' do
      expect(@test.basic(PR_NUMBER)).to be true
    end
  end

  describe '.basic-https' do
    it 'run on pr fixed number with basic options, https protocol enabled' do
      expect(@test.basic_https(PR_NUMBER)).to be true
    end
  end

  describe '.basic-check-option' do
    it 'gitarro run on first Pr open, with the check option, enabled' do
      ck_c = @rgit.create_comment(@pr, 'gitarro rerun check-option-test !!!')
      context = 'check-option-test'
      desc = 'dev-test-checkOption'
      result = @test.basic_check_test(@comm_st, context, desc)
      @rgit.delete_c(ck_c)
      expect(result).to be true
    end
  end
end

# secondary (not mandatory options tests)
describe 'cmdline secondary options' do
  before(:each) do
    @gitarrorepo = GIT_REPO
    @rgit = GitRemoteOperations.new(@gitarrorepo)
    @pr = @rgit.first_pr_open
    @test = GitarroTestingCmdLine.new(@gitarrorepo)
    # commit status
    @comm_st = @rgit.commit_status(@pr)
  end

  describe '.file_type_optional_option_not_set' do
    it 'we should run without filter and execute tests' do
      cont = 'file_type_option_optional'
      rcomment = @rgit.create_comment(@pr, "gitarro rerun #{cont} !!!")
      result = @test.file_type_unset(@comm_st, cont)
      @rgit.delete_c(rcomment.id)
      expect(result).to be true
    end
  end

  describe '.changelog-fail' do
    it 'gitarro changelog test should fail' do
      cont = 'changelog_shouldfail'
      rcomment = @rgit.create_comment(@pr, "gitarro rerun #{cont} !!!")
      expect(@test.changelog_should_fail(@comm_st)).to be true
      @rgit.delete_c(rcomment.id)
    end
  end

  describe '.changelog-pass' do
    it 'gitarro changelog test should pass' do
      comment = @rgit.create_comment(@pr, 'no changelog needed!')
      cont = 'changelog_shouldpass'
      rcomment = @rgit.create_comment(@pr, "gitarro rerun #{cont} !!!")
      result = @test.changelog_should_pass(@comm_st)
      @rgit.delete_c(comment.id)
      @rgit.delete_c(rcomment.id)
      expect(result).to be true
    end
  end
end

# secondary --changed_since
describe 'cmdline changed-since' do
  before(:each) do
    @gitarrorepo = GIT_REPO
    @rgit = GitRemoteOperations.new(@gitarrorepo)
    @pr = @rgit.first_pr_open
    @test = GitarroTestingCmdLine.new(@gitarrorepo)
    # commit status
    @comm_st = @rgit.commit_status(@pr)
  end

  describe '.changed_since_not_present' do
    it "gitarro should see PR ##{PR_NUMBER} when --change_since not present" do
      context = 'changed-since-not-present'
      pr = @rgit.pr_by_number(PR_NUMBER)
      comment = @rgit.create_comment(pr, "gitarro rerun #{context} !!!")
      result, output = @test.changed_since(@comm_st, -1, context)
      @rgit.delete_c(comment.id)
      expect(result).to be true
      expect(output).to match(/^\[PRS=true\].*/)
    end
  end

  describe '.changed_since_60' do
    it "gitarro should see PR ##{PR_NUMBER} changed in the last 60 seconds" do
      context = 'changed-since-60'
      pr = @rgit.pr_by_number(PR_NUMBER)
      comment = @rgit.create_comment(pr, "gitarro rerun #{context} !!!")
      result, output = @test.changed_since(@comm_st, 60, context)
      @rgit.delete_c(comment.id)
      expect(result).to be true
      expect(output).to match(/^\[PRS=true\].*/)
    end
  end

  describe '.changed_since_zero' do
    it 'gitarro should not see any PRs' do
      context = 'changed-since-zero'
      pr = @rgit.pr_by_number(PR_NUMBER)
      comment = @rgit.create_comment(pr, "gitarro rerun #{context} !!!")
      result, output = @test.changed_since(@comm_st, 0, context)
      @rgit.delete_c(comment.id)
      expect(result).to be true
      expect(output).to match(/^\[PRS=false\].*/)
    end
  end
end

# testing checks
describe 'testing checks' do
  before(:each) do
    @gitarrorepo = GIT_REPO
    @rgit = GitRemoteOperations.new(@gitarrorepo)
    @pr = @rgit.first_pr_open
    @test = GitarroTestingCmdLine.new(@gitarrorepo)
    # commit status
    @comm_st = @rgit.commit_status(@pr)
  end

  describe '.pr_requiring_test' do
    it "gitarro should see PR ##{PR_NUMBER} as requiring test" do
      context = 'pr-should-retest'
      pr = @rgit.pr_by_number(PR_NUMBER)
      comment = @rgit.create_comment(pr, "gitarro rerun #{context} !!!")
      result, output = @test.changed_since(@comm_st, 60, context)
      @rgit.delete_c(comment.id)
      expect(result).to be true
      expect(output).to match(/^\[TESTREQUIRED=true\].*/)
    end
  end

  describe '.pr_not_requiring_test' do
    it "gitarro should see PR ##{PR_NUMBER} as not requiring test" do
      context = 'pr-should-not-retest'
      pr = @rgit.pr_by_number(PR_NUMBER)
      comment = @rgit.create_comment(pr, "Updating PR for #{context} !!!")
      result, output = @test.changed_since(@comm_st, 60, context)
      @rgit.delete_c(comment.id)
      expect(result).to be true
      expect(output).not_to match(/^\[TESTREQUIRED=true\].*/)
    end
  end
end

# http cache tests
describe 'http_cache_tests' do
  before(:each) do
    @gitarrorepo = GIT_REPO
    @rgit = GitRemoteOperations.new(@gitarrorepo)
    @pr = @rgit.first_pr_open
    @test = GitarroTestingCmdLine.new(@gitarrorepo)
    # commit status
    @comm_st = @rgit.commit_status(@pr)
  end

  describe '.rate_limiting_cache' do
    it 'gitarro run 2 times, but we have only 1 ratelimiting' do
      cont = 'cachehttp_test'
      rcomment = @rgit.create_comment(@pr, "gitarro rerun #{cont} !!!")
      expect(@test.cache_test(cont)).to be true
      @rgit.delete_c(rcomment.id)
    end
  end
end
