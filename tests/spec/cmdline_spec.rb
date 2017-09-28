#! /usr/bin/ruby

require_relative 'test_lib.rb'

describe GitarroTestingCmdLine do
  before(:each) do
    @gitarrorepo = 'opensuse/gitarro'
    @rgit = GitRemoteOperations.new(@gitarrorepo)
    @pr = @rgit.first_pr_open
    @test = GitarroTestingCmdLine.new(@gitarrorepo)
    # commit status
    @comm_st = @rgit.commit_status(@pr)
  end

  describe '.basic' do
    it 'gitarro run on pr number 30 with basic options, cmdline' do
      expect(@test.basic).to be true
    end
  end

  describe '.basic-https' do
    it 'run on pr number 30 with basic options, https protocol enabled' do
      expect(@test.basic_https).to be true
    end
  end

  describe '.basic-check-option' do
    it 'gitarro run on first Pr open, with the check option, enabled' do
      ck_c = @rgit.create_comment(@pr, '@gitarro rerun check-option-test !!!')
      context = 'check-option-test'
      desc = 'dev-test-checkOption'
      result = @test.basic_check_test(@comm_st, context, desc)
      @rgit.delete_c(ck_c)
      expect(result).to be true
    end
  end

  describe '.changelog-fail' do
    it 'gitarro changelog test should fail' do
      expect(@test.changelog_should_fail(@comm_st)).to be true
    end
  end

  describe '.changelog-pass' do
    it 'gitarro changelog test should pass' do
      comment = @rgit.create_comment(@pr, 'no changelog needed!')
      cont = 'changelog_shouldpass'
      rcomment = @rgit.create_comment(@pr, "@gitarro rerun #{cont} !!!")
      result = @test.changelog_should_pass(@comm_st)
      @rgit.delete_c(comment.id)
      @rgit.delete_c(rcomment.id)
      expect(result).to be true
    end
  end
end
