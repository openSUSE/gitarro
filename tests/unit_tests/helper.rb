$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require 'minitest/autorun'
require 'minitest/reporters'
require 'minitest/mock'

require_relative '../../lib/gitarro/backend.rb'
require_relative '../../lib/gitarro/opt_parser.rb'
require_relative '../../lib/gitarro/git_op.rb'

Minitest::Reporters.use!(
  Minitest::Reporters::ProgressReporter.new,
  ENV,
  Minitest.backtrace_filter
)
