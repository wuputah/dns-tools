require "rubygems"
require "bundler"
Bundler.setup

$LOAD_PATH << File.dirname(__FILE__)

require 'dns'
run Sinatra::Application
