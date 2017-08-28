#! /usr/bin/ruby

require 'fileutils'
require 'timeout'

class GitOp
  attr_reader :git_dir
  def initialize(git_dir)
    @git_dir = git_dir
  end

  # this function merge the pr branch  into target branch,
  # where the author of pr wanted to submit
  def goto_prj_dir(repo)
    git_repo_dir = @git_dir + '/' + repo.split('/')[1]
    # chech that dir exist, otherwise clone it
    if File.directory?(@git_dir) == false
      FileUtils.mkdir_p(@git_dir)
      Dir.chdir @git_dir
      puts `git clone git@github.com:#{repo}.git`
    end
    begin
      # /tmp/gitbot, this is in case the dir already exists
      Dir.chdir git_repo_dir
    rescue
      # this is in case we clone the repo
      Dir.chdir repo.split('/')[1]
    end
  end

  def check_git_dir
    raise 'gitbot is not working on a git directory' if File.directory?('.git') == false
  end

  # merge pr_branch into upstream targeted branch
  def merge_pr_totarget(upstream, pr_branch, repo)
    goto_prj_dir(repo)
    # check that we are in a git dir
    check_git_dir
    `git checkout #{upstream}`
    `git remote update`
    `git fetch`
    `git pull origin #{upstream}`
    `git checkout -b PR-#{pr_branch} origin/#{pr_branch}`
    puts `git branch`
  end

  # cleanup the pr_branch(delete it)
  def del_pr_branch(upstream, pr)
    `git checkout #{upstream}`
    `git branch -D  PR-#{pr}`
  end
end
