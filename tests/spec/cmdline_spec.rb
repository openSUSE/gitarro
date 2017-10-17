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
  git_workspace = '/tmp/foo1'
  @test = GitarroTestingCmdLine.new(@gitarrorepo, git_workspace)
  # commit status
  @comm_st = @rgit.commit_status(@pr)
end

# do tests
describe 'cmdline foundamental' do
  before(:each) do
    init_tests_setup(GIT_REPO)
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

  describe '.run only one time with same context' do
    it 'with same context, we run only one time' do
      cont = 'file_type_option_optional'
      rcomment = @rgit.create_comment(@pr, "gitarro rerun #{cont} !!!")
      result = @test.only_onetime(@comm_st, cont)
      @rgit.delete_c(rcomment.id)
      # result contain false, because we are creating on 2nd run tscript
      # a file, which it must be not create to ensure that we run 1 time
      expect(result).to be false
    end
  end
end
