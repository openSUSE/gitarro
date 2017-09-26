#! /usr/bin/ruby

# this class is only private and helper for main class OptParser
class OptParserInternal
  attr_accessor :options
  def initialize
    @options = {}
    @options = options.clone if options.any?
  end
  # this is for testing

  def check_opt(opt)
    desc = 'Check if there is any PR requiring a test, but do not run it.'
    opt.on('-C', '--check', desc) { |check| @options[:check] = check }
  end

  def url_opt(opt)
    desc = 'Specify the URL to append to add to the GitHub review. ' \
           'Usually you will use an URL to the Jenkins build log.'
    opt.on('-u', "--url 'TARGET_URL'", desc) do |target_url|
      @options[:target_url] = target_url
    end
  end

  def https_opt(opt)
    @options[:https] = false
    https_desc = 'If present, use https instead of ssh for git operations'
    opt.on('--https', https_desc) { |https| @options[:https] = https }
  end

  def changelog_opt(opt)
    desc = 'Check if the PR includes a changelog entry ' \
           '(Automatically sets --file ".changes").'
    opt.on('--changelogtest', desc) do |changelogtest|
      @options[:changelog_test] = changelogtest
    end
  end

  def pr_number(opt)
    desc = 'Specify the PR number instead of checking all of them. ' \
           'This will force gitbot to run the against a specific PR number,' \
           'even if it is not needed (useful to use Jenkins with GitHub '\
           'webhooks).'
    opt.on('-P', "--PR 'NUMBER'", desc) do |pr_number|
      @options[:pr_number] = Integer(pr_number)
    end
  end

  def optional_options(opt)
    opt.separator ''
    opt.separator 'Optional options:'
    check_opt(opt)
    changelog_opt(opt)
    url_opt(opt)
    pr_number(opt)
    https_opt(opt)
  end

  # primary
  def context_opt(opt)
    desc = 'Context to set on comment (test name). For example: python-test.'
    opt.on('-c', "--context 'CONTEXT'", desc) do |context|
      @options[:context] = context
    end
  end

  def repo_opt(opt)
    desc = 'GitHub repository to look for PRs. For example: openSUSE/gitbot.'
    opt.on('-r', "--repo 'REPO'", desc) { |repo| @options[:repo] = repo }
  end

  def desc_opt(opt)
    opt.on('-d', "--description 'DESCRIPTION'", 'Test decription') do |d|
      @options[:description] = d
    end
  end

  def test_opt(opt)
    desc = 'Command, or full path to script/binary to be used to run the test.'
    opt.on('-t', "--test 'TEST.SH'", desc) do |test_file|
      @options[:test_file] = test_file
    end
  end

  def file_opt(opt)
    file_description = 'pr_file type to run the test against: .py, .rb'
    opt.on('-f', "--file \'.py\'", file_description) do |file_type|
      @options[:file_type] = file_type
    end
  end

  def git_opt(opt)
    desc = 'Specify a location where gitbot will clone the GitHub project. '\
           'If the dir does not exists, gitbot will create one. '\
           'For example: /tmp/'
    opt.on('-g', "--git_dir 'GIT_LOCAL_DIR'", desc) do |git_dir|
      @options[:git_dir] = git_dir
    end
  end

  def mandatory_options(opt)
    opt.separator 'Mandatory options:'
    repo_opt(opt)
    context_opt(opt)
    desc_opt(opt)
    test_opt(opt)
    file_opt(opt)
    git_opt(opt)
  end

  # all this methods are private
  def raise_incorrect_syntax(msg)
    puts "Incorrect syntax: #{msg}\n\n"
    puts 'Use option -h for help'
    exit 1
  end

  # set some default values
  def default_gitbot
    @options[:check] = false if @options[:check].nil?
    @options[:changelog_test] = false if @options[:changelog_test].nil?
    @options[:target_url] = '' if @options[:target_url].nil?
    @options[:file_type] = '.changes' if @options[:changelog_test]
  end

  def ck_mandatory_option(option)
    raise_incorrect_syntax("option --#{option} not found") if @options[option.to_sym].nil?
  end

  def parse(opt_parser)
    parse_options(opt_parser)
    mandatory_options = %w[repo context description file_type git_dir]
    mandatory_options.each { |opt| ck_mandatory_option(opt) }
    if @options[:test_file].nil? && @options[:changelog_test].nil?
      raise_incorrect_syntax('Incorrect syntax (use -h for help)')
    end
    default_gitbot
  end

  # option help
  def option_help(opt)
    opt.separator ''
    opt.separator 'Help:'
    opt.on('-h', '--help', 'help') do
      opt.separator ''
      opt.separator "Example: gitbot.rb -r openSUSE/gitbot -c 'python-test' "\
                    "-d 'someCoolTest' -g /tmp/pr-ruby01/ -t /tmp/test.sh "\
                    "-f '.py'"
      puts @opt_parser
      exit 0
    end
  end

  private

  def parse_options(opt_parser)
    opt_parser.parse!
  rescue OptionParser::ParseError
    raise_incorrect_syntax($ERROR_INFO.to_s)
  end
end

# Opt_parser class, is for getting needed options
#  this is the public class used by backend
class OptParser < OptParserInternal
  private

  def option_banner(opt)
    opt.banner = "Usage: gitbot.rb [options]\n\n" \
  end

  public

  def gitbot_options
    @opt_parser = OptionParser.new do |opt|
      option_banner(opt)
      mandatory_options(opt)
      optional_options(opt)
      option_help(opt)
    end
    parse(@opt_parser)
    @options
  end
end
