require 'rake/testtask'
require 'yaml'

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

task :spec do
  unless File.file?('.rspec.yml')
    puts '*******************************'
    puts 'Create a .rspec.yml file first'
    puts 'repo and pr_number as variables'
    puts
    puts 'EXAMPLE: repo: MalloZup/gitarro'
    puts '         pr_num: 1'
    puts '*******************************'
    return false
  end
  conf = YAML.load_file('.rspec.yml')
  repo = conf['repo']
  prnum = conf['pr_num']
  Dir.chdir('tests/spec') do
    sh "repo=#{repo} pr_num=#{prnum} rspec -fd cmdline_spec.rb"
  end
end
