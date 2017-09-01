#! /usr/bin/ruby

require 'English'
require 'fileutils'
require 'timeout'

# git operation for gitbot
class GitOp
  attr_reader :git_dir
  def initialize(git_dir)
    @git_dir = git_dir
    # prefix for the test pr that gitbot tests.
    @pr_fix = 'PR-'
  end

  def ck_or_clone_git(repo)
    return if File.directory?(@git_dir)
    FileUtils.mkdir_p(@git_dir)
    Dir.chdir @git_dir
    puts `git clone git@github.com:#{repo}.git`
  end

  # this function merge the pr branch  into target branch,
  # where the author of pr wanted to submit
  def goto_prj_dir(repo)
    git_repo_dir = @git_dir + '/' + repo.split('/')[1]
    # chech that dir exist, otherwise clone it
    ck_or_clone_git(repo)
    begin
      # /tmp/gitbot, this is in case the dir already exists
      Dir.chdir git_repo_dir
    rescue
      # this is in case we clone the repo
      Dir.chdir repo.split('/')[1]
    end
  end

  def check_git_dir
    msg_err = 'gitbot is not working on a git directory'
    raise msg_err if File.directory?('.git') == false
  end

  # this is for preventing that a test branch exists already
  # and we have some internal error
  def check_duplicata_pr_branch(pr)
    puts `git branch --list #{pr}`
    `git branch -D #{pr} 2>/dev/null` if $CHILD_STATUS.exitstatus.zero?
  end

  # merge pr_branch into upstream targeted branch
  def merge_pr_totarget(upstream, pr_branch, repo)
    goto_prj_dir(repo)
    # check that we are in a git dir
    check_git_dir
    `git checkout #{upstream}`
    check_duplicata_pr_branch("#{@pr_fix}#{pr_branch}")
    `git remote update`
    `git fetch`
    `git pull origin #{upstream}`
    `git checkout -b #{@pr_fix}#{pr_branch} origin/#{pr_branch}`
    puts `git branch`
  end

  # cleanup the pr_branch(delete it)
  def del_pr_branch(upstream, pr)
    `git checkout #{upstream}`
    `git branch -D  #{@pr_fix}#{pr}`
  end
end
