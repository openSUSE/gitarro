#! /usr/bin/ruby

require_relative 'rspec_helper.rb'
describe 'cmdline changed-since' do
  let(:gitarrorepo) { GIT_REPO }
  let(:rgit) { GitRemoteOperations.new(gitarrorepo) }
  let(:pr) { rgit.first_pr_open }
  let(:test) { GitarroTestingCmdLine.new(GIT_REPO, '/tmp/foo2') }
  let(:comm_st) { rgit.commit_status(pr) }

  it 'gitarro should see PR when --change_since not present' do
    context = 'changed-since-not-present'
    comment = rgit.create_comment(pr, "gitarro rerun #{context} !!!")
    result, output = test.changed_since(comm_st, -1, context)
    rgit.delete_c(comment.id)
    expect(result).to be true
    expect(output).to match(/^\[PRS=true\].*/)
  end

  it 'gitarro should see PR hanged in the last 60 seconds' do
    context = 'changed-since-60'
    comment = rgit.create_comment(pr, "gitarro rerun #{context} !!!")
    result, output = test.changed_since(comm_st, 60, context)
    rgit.delete_c(comment.id)
    expect(result).to be true
    expect(output).to match(/^\[PRS=true\].*/)
  end

  it 'gitarro should not see any PRs' do
    context = 'changed-since-zero'
    comment = rgit.create_comment(pr, "gitarro rerun #{context} !!!")
    result, output = test.changed_since(comm_st, 0, context)
    rgit.delete_c(comment.id)
    expect(result).to be true
    expect(output).to match(/^\[PRS=false\].*/)
  end
end
