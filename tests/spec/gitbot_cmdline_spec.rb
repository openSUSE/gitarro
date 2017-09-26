#! /usr/bin/ruby

require_relative 'test_lib.rb'

describe GitbotTestingCmdLine do
  before(:each) do
    @gitbotrepo = 'opensuse/gitbot'
    @rgit = GitRemoteOperations.new(@gitbotrepo)
    @pr = @rgit.first_pr_open
    @test = GitbotTestingCmdLine.new(@gitbotrepo)
    # commit status
    @comm_st = @rgit.commit_status(@pr)
  end

  describe '.basic' do
    it 'gitbot run on pr number 30 with basic options, cmdline' do
      expect(@test.basic).to be true
    end
  end

  describe '.basic-https' do
    it 'run on pr number 30 with basic options, https protocol enabled' do
      expect(@test.basic_https).to be true
    end
  end

  describe '.basic-check-option' do
    it 'gitbot run on first Pr open, with the check option, enabled' do
      ck_c = @rgit.create_comment(@pr, '@gitbot rerun check-option-test !!!')
      context = 'check-option-test'
      desc = 'dev-test-checkOption'
      result = @test.basic_check_test(@comm_st, context, desc)
      @rgit.delete_c(ck_c)
      expect(result).to be true
    end
  end

  describe '.changelog-fail' do
    it 'gitbot changelog test should fail' do
      expect(@test.changelog_should_fail(@comm_st)).to be true
    end
  end

  describe '.changelog-pass' do
    it 'gitbot changelog test should pass' do
      comment = @rgit.create_comment(@pr, 'no changelog needed!')
      cont = 'changelog_shouldpass'
      rcomment = @rgit.create_comment(@pr, "@gitbot rerun #{cont} !!!")
      result = @test.changelog_should_pass(@comm_st)
      @rgit.delete_c(comment.id)
      @rgit.delete_c(rcomment.id)
      expect(result).to be true
    end
  end
end
