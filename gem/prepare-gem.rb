#! /usr/bin/ruby
#
require 'fileutils'

# This will copy all files to gem dir for preparing a new gem.
class PrepareGemFS
  def initialize
    puts 'preparing gem'
  end

  def remove_all_dirs(dirs)
    dirs.each { |d| remove_dir(d) }
  end

  def copy_devel_dirs(dirs)
    dirs.each { |d| cp_dev(d) }
  end

  private

  def remove_dir(dir)
    FileUtils.rm_rf(dir)
  end

  def cp_dev(dir)
    FileUtils.cp_r(dir, 'lib/')
  end
end

class PrepareBin
  def initialize
   # is where the devel bin location file live
   @bin_d = 'bin/gitarro'

  end
 
  def copy_bin
    puts 'creating bin'
    # create bin dir
    FileUtils.mkdir 'bin'
    # copy gitarro.rb to bin
    FileUtils.cp '../gitarro.rb',  @bin_d  
  end

  def replace_contents(orig, new)
    puts '-- ' +  orig + ' replaced with ' + new
    # load the file as a string
    data = File.read(@bin_d) 
    filtered_data = data.gsub(orig, new)
    File.open(@bin_d, "w") { |f|  f.write(filtered_data) }
  end
end


# MAIN
DIRS_TO_REMOVE = %w[bin lib].freeze
DIRS_TO_DEVEL = %w[../lib].freeze

gitarrofs = PrepareGemFS.new

puts 'removing old dirs'
gitarrofs.remove_all_dirs(DIRS_TO_REMOVE)
puts 'copying latest lib'
gitarrofs.copy_devel_dirs(DIRS_TO_DEVEL)

# adapt some small changes to bin
puts 
bin = PrepareBin.new
bin.copy_bin
bin.replace_contents("require_relative", "require") 
bin.replace_contents("lib/gitarro", "gitarro") 

puts 
# BUILD

puts 'building gem !!!'

puts `gem build gitarro.gemspec`

puts 'DONE !!!'
