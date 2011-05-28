$: << File.join([File.dirname(__FILE__), "lib"])

require 'rubygems'
require 'rspec'
require 'mcollective'
require 'rspec/mocks'
require 'mocha'
require 'tempfile'

require 'mc_test_helper.rb'
require 'local_agent_test.rb'
require 'matchers.rb'


RSpec.configure do |config|
    config.mock_with :mocha
    config.include(Matchers)

    config.before :each do
        MCollective::PluginManager.clear
    end
end
