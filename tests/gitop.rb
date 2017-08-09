#! /usr/bin/ruby

require_relative 'helper'
require 'fileutils'

class SimpleTest < Minitest::Test
  def test_basic
    git = GitOp.new("gitty")
    assert_equal('gitty', git.git_dir)
  end
  
  def test_goto_prj_dir_function
    git = GitOp.new("gitty")
    # test the case the dir with repo doesn't exists
    git.goto_prj_dir("MalloZup/gitbot")
  end

  def test_goto_prj_already_exist_dir
    git = GitOp.new("gitty")
    git.goto_prj_dir("MalloZup/gitbot")
    FileUtils.rm_rf('gitty')     
  end

end
