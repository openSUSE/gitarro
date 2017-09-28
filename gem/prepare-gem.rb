#! /usr/bin/ruby
#
require 'fileutils'

# This will copy all files to gem dir for preparing a new gem.
class PrepareGem
  def initialize; end

  def remove_all_dirs(dirs)
    dirs.each { |d| remove_dir(d) }
  end

  private

  def remove_dir(dir)
    FileUtils.rm_rf(dir)
  end
end

DIRS_TO_REMOVE = %w[bin lib].freeze

gitarro = PrepareGem.new

gitarro.remove_all_dirs(DIRS_TO_REMOVE)
