require 'rake/testtask'

task default: %i[lint test buildgem]

task :test do
  Dir.chdir('tests/unit_tests') do
    Dir.glob('*.rb') do |rb_f|
      ruby rb_f
    end
  end
end
task :lint do
  sh 'rubocop '
  sh 'rubocop Rakefile'
end

task :buildgem do
  Dir.chdir('gem') do
    ruby 'prepare_gem.rb'
  end
end
