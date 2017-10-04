#! /usr/bin/ruby

require 'English'
require 'fileutils'
require 'timeout'

# This class is used by lib/backend.rb
# git operation for gitarro
class GitOp
  attr_reader :git_dir, :pr, :pr_fix, :repo_external, :repo_protocol
  def initialize(git_dir, pr, options)
    @git_dir = git_dir
    # prefix for the test pr that gitarro tests.
    @pr_fix = 'PR-'
    # pr object for extract all relev. data.
    @pr = pr
    # All gitarro options
    @options = options
    # object to handle external repos
    @repo_external = ExternalRepoGit.new(pr, options)
    gh = 'https://github.com/'
    gg = 'git@github.com:'
    @repo_protocol = @options[:https] ? gh : gg
  end

  # merge pr_branch into upstream targeted branch
  def merge_pr_totarget(upstream, pr_branch)
    goto_prj_dir
    check_git_dir
    `git checkout #{upstream}`
    check_duplicata_pr_branch("#{pr_fix}#{pr_branch}")
    `git remote update`
    `git fetch`
    `git pull origin #{upstream}`
    `git checkout -b #{pr_fix}#{pr_branch} origin/#{pr_branch}`
    return if $CHILD_STATUS.exitstatus.zero?
    # if it fails the PR contain a forked external repo
    repo_external.checkout_into
  end

  # cleanup the pr_branch(delete it)
  def del_pr_branch(upstream, pr)
    `git checkout #{upstream}`
    `git branch -D  #{pr_fix}#{pr}`
  end

  private

  def ck_or_clone_git
    git_repo_dir = git_dir + '/' + @options[:repo].split('/')[1]
    return if File.directory?(git_repo_dir)
    FileUtils.mkdir_p(git_dir) unless File.directory?(git_dir)
    Dir.chdir git_dir
    clone_repo
  end

  def clone_repo
    repo_url = "#{repo_protocol}#{@options[:repo]}.git"
    puts `git clone #{repo_url}`
    exit 1 if $CHILD_STATUS.exitstatus.nonzero?
  end

  # this function merge the pr branch  into target branch,
  # where the author of pr wanted to submit
  def goto_prj_dir
    git_repo_dir = git_dir + '/' + @options[:repo].split('/')[1]
    # chech that dir exist, otherwise clone it
    ck_or_clone_git
    begin
      # /tmp/gitarro, this is in case the dir already exists
      Dir.chdir git_repo_dir
    rescue Errno::ENOENT
      # this is in case we clone the repo
      Dir.chdir @options[:repo].split('/')[1]
    end
  end

  def check_git_dir
    msg_err = 'gitarro is not working on a git directory'
    raise msg_err if File.directory?('.git') == false
  end

  # this is for preventing that a test branch exists already
  # and we have some internal error
  def check_duplicata_pr_branch(pr)
    puts `git branch --list #{pr}`
    `git branch -D #{pr} 2>/dev/null` if $CHILD_STATUS.exitstatus.zero?
  end
end

# This private class handle the case the repo from PR
# comes from a user external repo
# PR open against: openSUSE/gitarro
# PR repo:  MyUSER/gitarro
class ExternalRepoGit
  attr_reader :pr, :rem_repo, :pr_fix
  def initialize(pr, options)
    # pr object for extract all relev. data.
    @pr = pr
    @pr_fix = 'PR-'
    @options = options
  end

  def checkout_into
    rem_repo = 'rem' + pr.head.ref
    add_remote(rem_repo)
    fetch_remote(rem_repo)
    checkout_to_rem_branch(rem_repo)
    remove_repo(rem_repo)
  end

  private

  def checkout_to_rem_branch(rem_repo)
    puts `git checkout -b #{pr_fix}#{branch_rem} #{rem_repo}/#{branch_rem}`
    exit 1 if $CHILD_STATUS.exitstatus.nonzero?
  end

  def branch_rem
    pr.head.ref
  end

  def add_remote(rem_repo)
    repo_url = @options[:https] ? pr.head.repo.html_url : pr.head.repo.ssh_url
    puts `git remote add #{rem_repo} #{repo_url}`
  end

  def fetch_remote(rem_repo)
    puts `git remote update`
    puts `git fetch`
    puts `git pull #{rem_repo} #{pr.head.ref}`
  end

  def remove_repo(rem_repo)
    puts `git remote remove #{rem_repo}`
  end
end
