#! /usr/bin/ruby

require_relative 'rspec_helper.rb'

# do tests
describe 'ckendcmdline foundamental' do
  let(:gitarrorepo) { GIT_REPO }
  let(:rgit) { GitRemoteOperations.new(gitarrorepo) }
  let(:pr) { rgit.first_pr_open }
  let(:test) { GitarroTestingCmdLine.new(gitarrorepo, '/tmp/gita') }
  let(:comm_st) { rgit.commit_status(pr) }

  it 'gitarro run on fixed pr_number with basic options, cmdline' do
    expect(test.basic(PR_NUMBER)).to be true
  end

  it 'run on pr fixed number with basic options, https protocol enabled' do
    expect(test.basic_https(PR_NUMBER)).to be true
  end

  it 'gitarro run on first Pr open, with the check option, enabled' do
    ck_c = rgit.create_comment(pr, 'gitarro rerun check-option-test !!!')
    result = test.basic_check_test(comm_st, 'check-option-test', 'check-test')
    rgit.delete_c(ck_c)
    expect(result).to be true
  end

  it 'with same context, we run only one time' do
    cont = 'file_type_option_optional'
    rcomment = rgit.create_comment(pr, "gitarro rerun #{cont} !!!")
    result = test.only_onetime(comm_st, cont)
    rgit.delete_c(rcomment.id)
    # result contain false, because we are creating on 2nd run tscript
    # a file, which it must be not create to ensure that we run 1 time
    expect(result).to be false
  end
end
