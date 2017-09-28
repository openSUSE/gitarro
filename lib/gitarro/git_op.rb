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
    repo_name = options[:repo].split('/')[1]
    # Directory where the repository with the code to test will live
    # append repository name to be retrocompatible
    # But if it exists, use /tmp/gitbot/<repo_name>
    @git_dir = git_dir + '/' + repo_name
    # Clone style
    @no_merge_upstream = options[:no_merge_upstream]
  end

  def get_pr(pr_number, pr_base_ref)
    git_init(@git_dir)
    git_remote_add('origin', @repo_url)
    # PR standalone, last commit
    if @no_merge_upstream
      git_pull('origin', "refs/pull/#{pr_number}/head")
    # The PR plus all commits from base until the common ancestor
    else
      # Rewind until we can pull --rebase pr_base_ref
      git_pull_rewind('origin', "refs/pull/#{pr_number}/head", pr_base_ref)
    end
  end

  def can_pull_merge(origin, base_ref, depth)
    puts `git pull --depth #{depth} --no-edit #{origin} #{base_ref}`
    $CHILD_STATUS.exitstatus.zero?
  end

  def error_max_rewind(cur, max, ref)
    return unless cur >= max
    puts "\nERROR: Rewinded more than commits 100 without being able to merge!"
    puts "And cound not find it!\n\n"
    puts "Either PR lacks of a parent commit at #{ref} you just have too"
    puts 'many commits and you need to squash your commits to make the PR '
    puts "easier!\n"
    exit 1
  end

  def git_init(dir)
    # Remove the directory if it exists
    FileUtils.remove_entry_secure(dir) if File.directory?(dir)
    puts `git init #{dir}`
    exit 1 if $CHILD_STATUS.exitstatus.nonzero?
    Dir.chdir dir
  end

  def git_remote_add(remote, url)
    puts `git remote add #{remote} #{url}`
    exit 1 if $CHILD_STATUS.exitstatus.nonzero?
  end

  def git_pull_rewind(origin, ref, base_ref)
    # Download commits backwards starting from PR head until we can rebase
    # base_ref
    i = 1
    loop do
      puts "\n*** Downloading from #{origin} #{ref}, depth #{i}\n\n"
      git_pull(origin, ref, i)
      puts "\n*** Downloading from #{origin} #{base_ref}, depth #{i}\n\n"
      break if can_pull_merge(origin, base_ref, i)
      i += 1
      error_max_rewind(i, 101, base_ref)
    end
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
