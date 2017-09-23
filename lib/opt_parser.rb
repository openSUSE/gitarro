#! /usr/bin/ruby

# Class for gathering mandatory options via cmdline

# this class is only private and helper for main class OptParser
class OptParserInternal
  attr_accessor :options
  def initialize
    @options = {}
    @options = options.clone if options.any?
  end
  # this is for testing

  def check_opt(opt)
    ck_desc = 'check, if a PR requires test' \
   'Run in checkmode and test if there is a Pull Request which requires a test'
    opt.on('-C', '--check', ck_desc) { |check| @options[:check] = check }
  end

  def url_opt(opt)
    url_desc = 'specify the url to append to github review' \
                ' usually is the jenkins url of the job'
    opt.on('-u', '--url TARGET_URL', url_desc) do |target_url|
      @options[:target_url] = target_url
    end
  end

  def changelog_opt(opt)
    changelog_desc = 'check if the PR include a changelog entry' \
    ' Automatically set --file \".changes\"'
    opt.on('--changelogtest', changelog_desc) do |changelogtest|
      @options[:changelog_test] = changelogtest
    end
  end

  def pr_number(opt)
    pr_desc = 'specify the pr number for running the test.' \
              'force gitbot to run tests against a specific PR NUMBER,' \
              'even if the test was already run'
    opt.on('-P', '--PR NUMBER', pr_desc) do |pr_number|
      @options[:pr_number] = Integer(pr_number)
    end
  end

  def secondary_options(opt)
    opt.separator 'OPTIONAL Options'
    check_opt(opt)
    changelog_opt(opt)
    url_opt(opt)
    pr_number(opt)
  end

  # primary
  def context_opt(opt)
    opt.on('-c', "--context 'CONTEXT'", 'context to set on comment' \
                                 ' EXAMPLE: CONTEXT: python-test') do |context|
      @options[:context] = context
    end
  end

  def repo_opt(opt)
    opt.on('-r', "--repo 'REPO'", 'github repo you want to run test against' \
                            ' EXAMPLE: USER/REPO  MalloZup/gitbot') do |repo|
      @options[:repo] = repo
    end
  end

  def desc_opt(opt)
    opt.on('-d', "--description 'DESCRIPTION'", 'description for test') do |d|
      @options[:description] = d
    end
  end

  def test_opt(opt)
    opt.on('-t', "--test 'TEST.SH'", 'fullpath to the' \
           'script which contain test to be executed against pr') do |test_file|
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
    git_d = 'specify a location where gitbot will clone the github project' \
    'EXAMPLE : /tmp/pr-test/ if the dir doesnt exists, gitbot will create one.'
    opt.on('-g', "--git_dir 'GIT_LOCAL_DIR'", git_d) do |git_dir|
      @options[:git_dir] = git_dir
    end
  end

  def mandatory_options(opt)
    opt.separator 'MANDATORY Options'
    repo_opt(opt)
    context_opt(opt)
    desc_opt(opt)
    test_opt(opt)
    file_opt(opt)
    git_opt(opt)
  end

  # all this methods are private
  def raise_verbose_help(msg)
    puts @opt_parser
    puts "************************************************\n"
    raise OptionParser::MissingArgument, msg
  end

  # set some default values
  def default_gitbot
    @options[:check] = false if @options[:check].nil?
    @options[:changelog_test] = false if @options[:changelog_test].nil?
    @options[:target_url] = '' if @options[:target_url].nil?
    @options[:file_type] = '.changes' if @options[:changelog_test]
  end

  def ck_mandatory_option(option)
    raise_verbose_help(option) if @options[option.to_sym].nil?
  end

  def parse(opt_parser)
    opt_parser.parse!
    mandatory_options = %w[repo context description file_type git_dir]
    mandatory_options.each do |opt|
      ck_mandatory_option(opt)
    end
    if @options[:test_file].nil? && @options[:changelog_test].nil?
      raise_verbose_help('SCRIPT FILE')
    end
    default_gitbot
  end

  # option help
  def option_help(opt)
    opt.separator 'HELP'
    opt.on('-h', '--help', 'help') do
      puts @opt_parser
      puts "***************************************************************\n"
      exit 0
    end
  end
end

# Opt_parser class, is for getting needed options
#  this is the public class used by backend
class OptParser < OptParserInternal
  private

  # option banner gitbot
  def option_banner(opt)
    name = './gitbot.rb'
    opt.banner = "************************************************\n" \
        "Usage: gitbot [OPTIONS] \n" \
        " EXAMPLE: ======> #{name} -r openSUSE/gitbot -c \"pysthon-test\" " \
        "-d \"someCoolTest\" -g /tmp/pr-ruby01/ -t /tmp/test.sh -f \".py\"\n\n"
  end

  public

  def gitbot_options
    @opt_parser = OptionParser.new do |opt|
      option_banner(opt)
      mandatory_options(opt)
      secondary_options(opt)
      option_help(opt)
    end
    parse(@opt_parser)
    @options
  end
end
