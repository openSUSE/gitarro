
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gitbot/version'

Gem::Specification.new do |s|
  s.name        = 'gitbot'
  s.version     = Gitbot::VERSION
  s.date        = '2017-09-26'
  s.summary     = 'gitbot gem'
  s.description = 'Gitbot run tests on GitHub PRs using almost any script,' \
                   'language or binary, it integrate easy with other tools.'
  s.authors     = 'Dario Maiocchi'
  s.email       = 'dmaiocchi@suse.com'
  s.license     = 'MIT'
  s.homepage	= 'https://github.com/openSUSE/gitbot'
  s.require_paths = ['lib']
  s.files = ['lib/gitbot/gitbot_backend.rb',
             'lib/gitbot/opt_parser.rb', 'lib/gitbot/git_op.rb',
             'lib/gitbot/version.rb']
  s.executables = 'gitbot'
  s.add_dependency 'english', '~> 0.6'
  s.add_dependency 'minitest', '~> 5.9'
  s.add_dependency 'minitest-reporters', '~> 1.1'
  s.add_dependency 'netrc', '~> 0.11'
  s.add_dependency 'octokit', '~> 4.7'
  s.add_dependency 'rake', '~> 10.5'
  s.add_dependency 'rubocop', '~> 0.49'
  s.add_dependency 'rspec', '~> 3.6'
end
