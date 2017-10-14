require 'rake/testtask'
require 'yaml'

task default: %i[lint reek test buildgem]

def check_conf_file
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

def load_yaml_conf
  check_conf_file
  conf = YAML.load_file('.rspec.yml')
  [conf['repo'], conf['pr_num']]
end
# FIXME: refactor this better
@repo, @prnum = load_yaml_conf


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
task :spec_cmdline do
  Dir.chdir('tests/spec') do
    sh "repo=#{@repo} pr_num=#{@prnum} rspec -fd cmdline_spec.rb"
  end
end

task :secondary do
  Dir.chdir('tests/spec') do
    sh "repo=#{@repo} pr_num=#{@prnum} rspec -fd secondary_spec.rb"
  end
end

task :secondary2 do
  Dir.chdir('tests/spec') do
    sh "repo=#{@repo} pr_num=#{@prnum} rspec -fd secondary2_spec.rb"
  end
end

# this run them togheter in parallel.
multitask :spec => [:spec_cmdline, :secondary , :secondary2]

task :reek do
  # add files that are safe without errors
  # FIXME: addmore(atm to much errors)
  #  must_pass_f =['gitarro.rb', "lib/gitarro/*.rb"]
  must_pass_f = ['gitarro.rb']
  must_pass_f.each do |f|
    sh "reek #{f}"
  end
end
