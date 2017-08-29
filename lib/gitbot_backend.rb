#! /usr/bin/ruby

require 'octokit'
require 'optparse'
require 'English'
require_relative 'opt_parser'
require_relative 'git_op'

# this class is the backend of gitbot, were we execute the tests and so on
class GitbotBackend
  attr_accessor :j_status, :options
  def initialize
    Octokit.auto_paginate = true
    @client = Octokit::Client.new(netrc: true)
    @options = OptParser.get_options
    @j_status = ''
    # each options will generate a object variable dinamically
    @options.each do |key, value|
      instance_variable_set("@#{key}", value)
      self.class.send(:attr_accessor, key)
    end
  end

  # run validation script for validating the PR.
  def run_script
    f_not_exist_msg = "\'#{@test_file}\' doesn't exists.Enter valid file, -t option"
    raise f_not_exist_msg if File.file?(@test_file) == false

    out = `#{@test_file}`
    @j_status = 'failure' if $CHILD_STATUS.exitstatus.nonzero?
    @j_status = 'success' if $CHILD_STATUS.exitstatus.zero?
    puts out
  end
end
