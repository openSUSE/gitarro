#! /usr/bin/ruby

require_relative 'helper'

#************************************************
#Usage: gitbot [OPTIONS] 
# EXAMPLE: ======> ./gitbot.rb -r MalloZup/galaxy-botkins -c "python-test" -d "pyflakes_linttest" -g /tmp/pr-ruby01/ -t /tmp/tests-to-be-executed -f ".py"
#
#MANDATORY Options
#    -r, --repo 'REPO'                github repo you want to run test against EXAMPLE: USER/REPO  MalloZup/gitbot
#    -c, --context 'CONTEXT'          context to set on comment EXAMPLE: CONTEXT: python-test
#    -d, --description 'DESCRIPTION'  description to set on comment
#    -t, --test 'TEST.SH'             fullpath to thescript which contain test to be executed against pr
#    -f, --file '.py'                 specify the file type of the pr which you wantto run the test against ex .py, .java, .rb
#    -g, --git_dir 'GIT_LOCAL_DIR'    specify a location where gitbot will clone the github projectEXAMPLE : /tmp/pr-test/ if the dir doesnt exists, gitbot will create one.
#OPTIONAL Options
#    -u, --url TARGET_URL             specify the url to append to github review usually is the jenkins url of the job
#HELP
#    -h, --help                       help
#************************************************




class SimpleTest < Minitest::Test

  def set_option(hash, s)
    OptParser.options = hash
    ex = assert_raises OptionParser::MissingArgument do
      OptParser.get_options
    end
    assert_equal("missing argument: #{s}", ex.message)
  end 

  def test_partial_import
    hash =  {repo: 'gino/gitbot'} 
    hash1 = {repo: 'gino/gitbot', context: 'python-t', description: 'functional', test: 'gino.sh'}
    set_option(hash, 'CONTEXT')
    set_option(hash1, 'SCRIPT FILE')
  end

  def test_full_option_import
   hash = {repo: 'gino/gitbot', context: 'python-t', description: 'functional', test_file: 'gino.sh', file_type: '.sh', git_dir: 'gitty'}
   OptParser.options = hash
   options = OptParser.get_options
   assert_equal('gino/gitbot', options[:repo])
   assert_equal('python-t', options[:context])
   assert_equal('functional', options[:description])
   assert_equal('gino.sh', options[:test_file])
   assert_equal('.sh', options[:file_type])
   assert_equal('gitty', options[:git_dir])
  end
end
