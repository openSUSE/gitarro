require 'rake/testtask'
require 'yaml'

task default: %i[lint reek test buildgem]

# this class load configuration for rspec
class RspecConfiguration
  def self.check_conf_file
    return true if File.file?('.rspec.yml')
    puts '*******************************'
    puts 'Create a .rspec.yml file first'
    puts 'repo and pr_number as variables'
    puts
    puts 'EXAMPLE: repo: MalloZup/gitarro'
    puts '         pr_num: 1'
    puts '*******************************'
    false
  end

  def self.load_yaml_conf
    check_conf_file
    conf = YAML.load_file('.rspec.yml')
    [conf['repo'], conf['pr_num']]
  end
end

@repo, @prnum = RspecConfiguration.load_yaml_conf

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

#  this are the differents testsuites
TESTSUITES = %w[cmdline_spec secondary2_spec secondary_spec].freeze

# run spec testsuite ( a file in parallel)
def run_suite(repo, prnum, task_name)
  sh "repo=#{repo} pr_num=#{prnum} " \
  "rspec -fd -fh --out #{task_name}.html" \
  " --order rand tests/spec/#{task_name}.rb"
end

TESTSUITES.each do |task_name|
  task task_name do
    run_suite(@repo, @prnum, task_name)
  end
end

# this run them togheter in parallel.
multitask spec: TESTSUITES do
  puts 'Rspec test done!'
end

task :reek do
  # add files that are safe without errors
  # FIXME: addmore(atm to much errors)
  #  must_pass_f =['gitarro.rb', "lib/gitarro/*.rb"]
  must_pass_f = ['gitarro.rb']
  must_pass_f.each do |f|
    sh "reek #{f}"
  end
end
