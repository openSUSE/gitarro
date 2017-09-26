Gem::Specification.new do |s|
  s.name        = "gitbot"
  s.version     = "0.0.1"
  s.date        = "2017-09-26"
  s.summary     = "gitbot gem"
  s.description = "Gitbot allow you to run tests on Git Hub Pull Requests (also known as PRs) using almost any script, language or binary and providing easy integration with other tools."
  s.authors     = "Dario Maiocchi"
  s.email       = "dmaiocchi@suse.com"
  s.files       = ["lib/gitbot.rb", "lib/gitbot/gitbot_backend.rb", "lib/gitbot/git_op.rb", "lib/gitbot/opt_parser.rb"]
  s.license     = "MIT"
  s.homepage	= "https://github.com/openSUSE/gitbot"
  s.add_dependency 'english', '~> 0.6'
  s.add_dependency 'minitest', '~> 5.9'
  s.add_dependency 'minitest-reporters', '~> 1.1'
  s.add_dependency 'netrc', '~> 0.11'
  s.add_dependency 'octokit', '~> 4.7'
  s.add_dependency 'rake', '~> 10.5'
  s.add_dependency 'rubocop', '~> 0.49'
  s.add_dependency 'rspec', '~> 3.6'
  s.required_ruby_version = '~> 2.3'
end
