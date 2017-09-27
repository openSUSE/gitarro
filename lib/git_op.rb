#! /usr/bin/ruby

require 'fileutils'
require 'English'

# Representation of a commit with its attributes
class Commit
  attr_accessor :hash, :author_name, :author_email, :date
end

# git operation for gitbot
class GitOp
  def initialize(git_dir, options)
    # GitHub URL depending on protocol
    @repo_url = options[:https] ? 'https://github.com/' : 'git@github.com:'
    @repo_url = @repo_url + options[:repo] + '.git'
    # Repository name (without project)
    repo_name = options[:repo].split('/')[0]
    # Directory where the repository with the code to test will live
    # append repository name to be retrocompatible
    # But if it exists, use /tmp/gitbot/<repo_name>
    @git_dir = git_dir + '/' + repo_name
  end

  def get_pr(pr_number)
    git_init(@git_dir)
    git_config('remote.origin.url', @repo_url)
    git_pull('origin', "refs/pull/#{pr_number}/head")
  end

  def git_init(dir)
    # Remove the directory if it exists
    FileUtils.remove_entry_secure(dir) if File.directory?(dir)
    puts `git init #{dir}`
    exit 1 if $CHILD_STATUS.exitstatus.nonzero?
    Dir.chdir dir
  end

  def git_config(param, value)
    puts `git config #{param} #{value}`
    exit 1 if $CHILD_STATUS.exitstatus.nonzero?
  end

  def git_pull(remote, ref, depth = 1)
    # To support changing pulling depth in the future
    depth_param = depth == -1 ? '' : "--depth #{depth}"
    puts `git pull #{depth_param} #{remote} #{ref}`
    exit 1 if $CHILD_STATUS.exitstatus.nonzero?
  end

  def current_commit
    commit = Commit.new
    commit.hash = `git log --pretty=format:'%H' -n 1`
    commit.author_name = `git log --pretty=format:'%an' -n 1`
    commit.author_email = `git log --pretty=format:'%ae' -n 1`
    commit.date = `git log --pretty=format:'%ad' -n 1`
    commit
  end

  def print_commit_info(pr)
    commit = current_commit
    puts "\nThe following commit is to be tested:\n" \
      "- LOCAL HASH:  #{commit.hash}\n" \
      "- REPO ORIG:   #{pr.head.repo.full_name}\n" \
      "- BRANCH_ORIG: #{pr.head.ref}\n" \
      "- HASH_ORIG:   #{pr.head.sha}\n\n" \
  end
end
