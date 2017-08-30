#! /usr/bin/ruby

# Opt_parser module, is for getting needed options

module OptParser
  # this is for testing
  class << self; attr_accessor :options; end
  @options = {}
  @options = options.clone if options.any? == true

  def self.raise_verbose_help(msg)
    puts @opt_parser
    puts "************************************************\n"
    raise OptionParser::MissingArgument, msg
  end

  # set some default values
  def self.default_gitbot
    @options[:check] = false if @options[:check].nil?
    @options[:changelog_test] = false if @options[:changelog_test].nil?
    @options[:file_type] = '.changes' if @options[:changelog_test]
  end

  def self.parse(opt_parser)
    opt_parser.parse!
    OptParser.raise_verbose_help('REPO') if @options[:repo].nil?
    OptParser.raise_verbose_help('CONTEXT') if @options[:context].nil?
    OptParser.raise_verbose_help('DESCRIPTION') if @options[:description].nil?
    OptParser.raise_verbose_help('SCRIPT FILE') if @options[:test_file].nil?
    OptParser.raise_verbose_help('TYPE FILE') if @options[:file_type].nil?
    OptParser.raise_verbose_help('GIT LOCAL DIR') if @options[:git_dir].nil?
    OptParser.default_gitbot
  end

  def OptParser.gitbot_options
    name = './gitbot.rb'
    @opt_parser = OptionParser.new do |opt|
      opt.banner = "************************************************\n" \
        "Usage: gitbot [OPTIONS] \n" \
        " EXAMPLE: ======> #{name} -r openSUSE/gitbot -c \"pysthon-test\" " \
        "-d \"pyflakes_linttest\" -g /tmp/pr-ruby01/ -t /tmp/tests-to-be-executed -f \".py\"\n\n"
      opt.separator 'MANDATORY Options'

      opt.on('-r', "--repo 'REPO'", 'github repo you want to run test against' \
                              ' EXAMPLE: USER/REPO  MalloZup/gitbot') do |repo|
        @options[:repo] = repo
      end

      opt.on('-c', "--context 'CONTEXT'", 'context to set on comment' \
                                  ' EXAMPLE: CONTEXT: python-test') do |context|
        @options[:context] = context
      end

      opt.on('-d', "--description 'DESCRIPTION'", 'description to set on comment') do |description|
        @options[:description] = description
      end

      opt.on('-t', "--test 'TEST.SH'", 'fullpath to the' \
             'script which contain test to be executed against pr') do |test_file|
        @options[:test_file] = test_file
      end

      opt.on('-f', "--file \'.py\'", 'specify the file type of the pr which you want' \
                  'to run the test against ex .py, .java, .rb') do |file_type|
        @options[:file_type] = file_type
      end

      opt.on('-g', "--git_dir 'GIT_LOCAL_DIR'", 'specify a location where gitbot will clone the github project' \
                  'EXAMPLE : /tmp/pr-test/ if the dir doesnt exists, gitbot will create one.') do |git_dir|
        @options[:git_dir] = git_dir
      end

      opt.separator 'OPTIONAL Options'

      opt.on('-u', '--url TARGET_URL', 'specify the url to append to github review' \
                  ' usually is the jenkins url of the job') do |target_url|
        @options[:target_url] = target_url
      end

      opt.on('-s', '--secs TIMEOUT', 'specify the secs you want to wait/sleep if the' \
                  ' gitbot is not finding any valid PRs to review. (usefull to spare jenkins jobs history)') do |timeout|

        @options[:timeout] = Integer(timeout)
      end

      opt.on('--changelogtest', 'check if the PR include a changelog entry. Automatically set --file ".changes"') do |changelogtest|
        @options[:changelog_test] = changelogtest
      end

      opt.on('-C', '--check', 'check, if a PR requires test' \
             'Run in checkmode and test if there is a Pull Request which requires a test') do |check|
        @options[:check] = check
      end

      opt.separator 'HELP'
      opt.on('-h', '--help', 'help') do
        puts @opt_parser
        puts "***************************************************************\n"
        exit 0
      end
    end
    OptParser.parse(@opt_parser)
    @options
  end
end
