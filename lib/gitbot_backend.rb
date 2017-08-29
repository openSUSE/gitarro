#! /usr/bin/ruby

require 'octokit'
require 'optparse'
require_relative 'opt_parser'
require_relative 'git_op'

# this class is the backend of gitbot, were we execute the tests and so on
class GitbotBackend
  attr_accessor :j_status, :options
  def initialize()
    Octokit.auto_paginate = true
    @client = Octokit::Client.new(netrc: true)
    @options = OptParser.get_options
    @j_status = ''
    # each options will generate a object variable
    @options.each do |key, value|
      instance_variable_set("@#{key}", value)
      self.class.send(:attr_accessor, key)
    end
  end
end
