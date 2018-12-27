#! /usr/bin/ruby

require_relative 'rspec_helper.rb'

describe 'secondary2 features' do
  let(:gitarrorepo) { GIT_REPO }
  let(:rgit) { GitRemoteOperations.new(gitarrorepo) }
  let(:pr) { rgit.first_pr_open }
  let(:test) { GitarroTestingCmdLine.new(gitarrorepo, '/tmp/bar') }
  let(:comm_st) { rgit.commit_status(pr) }

  it 'gitarro should see PR requiring test through a comment' do
    context = 'pr-should-retest'
    comment = rgit.create_comment(pr, "gitarro rerun #{context} !!!")
    result, output = test.changed_since(comm_st, 60, context)
    rgit.delete_c(comment.id)
    expect(result).to be true
    expect(output).to match(/^\[TESTREQUIRED=true\].*/)
  end

  it 'gitarro should see PR as not requiring test through a comment' do
    context = 'pr-should-not-retest'
    comment = rgit.create_comment(pr, "Updating PR for #{context} !!!")
    result, output = test.changed_since(comm_st, 60, context)
    rgit.delete_c(comment.id)
    expect(result).to be true
    expect(output).not_to match(/^\[TESTREQUIRED=true\].*/)
  end

  it 'gitarro should see PR requiring test through a checkbox' do
    context = 'pr-should-retest'
    rgit.change_description(pr, "[x] Re-run test \"#{context}\"")
    result, output = test.changed_since(comm_st, 60, context)
    expect(result).to be true
    expect(output).to match(/^\[TESTREQUIRED=true\].*/)
  end

  it 'gitarro should see PR as not requiring test through a checkbox' do
    context = 'pr-should-not-retest'
    rgit.change_description(pr, "[ ] Re-run test \"#{context}\"")
    result, output = test.changed_since(comm_st, 60, context)
    expect(result).to be true
    expect(output).not_to match(/^\[TESTREQUIRED=true\].*/)
  end

  # env variables
  it 'Passing env variable to script, we can use them in script' do
    cont = 'env_test_script'
    rcomment = rgit.create_comment(pr, "gitarro rerun #{cont} !!!")
    stdout = test.env_test(cont)
    gitarro_pr_author = pr.head.user.login.to_s
    expect(stdout).to match("GITARRO_PR_NUMBER: #{pr.number}")
    expect(stdout).to match("GITARRO_PR_TITLE: #{pr.title}")
    expect(stdout).to match("GITARRO_PR_AUTHOR: #{gitarro_pr_author}")
    expect(stdout).to match("GITARRO_PR_TARGET_REPO: #{GIT_REPO}")
    rgit.delete_c(rcomment.id)
  end

  # don't use shallow clone (enabled by default)
  it 'dont use shallow clone but full one clone' do
    cont = 'noshallowclone'
    rcomment = rgit.create_comment(pr, "gitarro rerun #{cont} !!!")
    result = test.noshallow(comm_st, cont)
    rgit.delete_c(rcomment.id)
    expect(result).to be true
  end

end
