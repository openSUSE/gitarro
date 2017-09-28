GITARRO_VERSION = '0.1.0'.freeze

Gem::Specification.new do |s|
  s.name = 'gitarro'
  s.version = GITARRO_VERSION
  s.date        = '2017-09-26'
  s.summary     = 'gitarro gem'
  s.description = 'gitarro run tests on GitHub PRs using almost any script,' \
                   'language or binary, it integrate easy with other tools.'
  s.authors     = 'Dario Maiocchi'
  s.email       = 'dmaiocchi@suse.com'
  s.license     = 'MIT'
  s.homepage	= 'https://github.com/openSUSE/gitarro'
  s.require_paths = ['lib']
  s.files = ['lib/gitarro/backend.rb',
             'lib/gitarro/opt_parser.rb', 'lib/gitarro/git_op.rb']
  s.executables = 'gitarro'
  s.add_dependency 'english', '~> 0.6'
  s.add_dependency 'minitest', '~> 5.9'
  s.add_dependency 'minitest-reporters', '~> 1.1'
  s.add_dependency 'netrc', '~> 0.11'
  s.add_dependency 'octokit', '~> 4.7'
  s.add_dependency 'rake', '~> 10.5'
  s.add_dependency 'rubocop', '~> 0.49'
  s.add_dependency 'rspec', '~> 3.6'
end
