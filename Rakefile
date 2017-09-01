require 'rake/testtask'

task default: %i[lint test]

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['tests/*.rb']
  t.verbose = true
end

task :lint do
  sh 'rubocop **/*.rb'
  sh 'rubocop Rakefile'
end
