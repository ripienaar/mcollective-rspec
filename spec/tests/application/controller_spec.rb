#! /usr/bin/env ruby

require File.join([File.dirname(__FILE__), '/../../spec_helper'])

module MCollective

    describe "controller  application" do

        before do
            @util = MCollective::Test::ApplicationTest.new("controller", :config => {:libdir => "/usr/libexec/mcollective"})
            @app = @util.plugin
        end

        describe "#application_description" do
            it "should have a description set" do
                @app.should have_a_description
            end
        end

        describe "#post_option_parser" do
            it "should set a command" do
                ARGV << "test"

                configuration = {}
                @app.post_option_parser(configuration)
                configuration[:command].should == "test"
            end
        end

        describe "#validate_configuration" do
            it "should validate that command has been set" do
                configuration = {:command => "test"}
                @app.validate_configuration(configuration)
            end

            it "should raise and exception if command has not been set" do
                lambda{@app.validate_configuration({})}.should raise_error
            end
        end

        describe "#main" do

            before do
                @mock_client = mock
                @mock_client.stubs(:options=)

                @app.stubs(:options).returns(:config => "config")
                MCollective::Client.expects(:new).returns(@mock_client)
                @mock_client.expects(:disconnect)
                @mock_client.expects(:display_stats)
            end

            it "should print statistics if command is stats" do
                @app.stubs(:configuration).returns(:command => "stats")
                @mock_client.expects(:discovered_req).with("stats", "mcollective").yields(@util.create_response("node1", :value => "1"))
                @app.expects(:print_statistics)
                @app.main
            end

            it "should print sender and message body if command is reload_agent" do
                @app.stubs(:configuration).returns(:command => "reload_agent?")
                @mock_client.expects(:discovered_req).with("reload_agent?", "mcollective").yields(@util.create_response("node1", :value => "1"))
                @app.expects(:printf)
                @app.main
           end

           it "should print sender and pp message body if command is neither stats nor reload_agent and verbose is set" do
               @app.stubs(:configuration).returns(:command => "no_match")
               @mock_client.expects(:discovered_req).with("no_match", "mcollective").yields(@util.create_response("node1", :value => "1"))
               @app.stubs(:options).returns(:config => "config", :verbose => true)
               @app.expects(:puts)
               @app.expects(:pp)
               @app.main
           end

           it "should print the sender name if command is neither stats nor reload_agent and verbose is not set" do
               @app.stubs(:configuration).returns(:command => "no_match")
               @mock_client.expects(:discovered_req).with("no_match", "mcollective").yields(@util.create_response("node1", :value => "1"))
               @app.stubs(:options).returns(:config => "config", :verbose => false)
               @app.expects(:print).with("node1")
               @app.main
           end
        end

        describe "#print_statistics" do

            it "should print statistics" do
                @mock_client = mock
                @mock_client.stubs(:options=)

                @app.stubs(:options).returns(:config => "config")
                MCollective::Client.expects(:new).returns(@mock_client)
                @mock_client.expects(:disconnect)
                @mock_client.expects(:display_stats)

                @app.stubs(:configuration).returns(:command => "stats")
                @mock_client.expects(:discovered_req).with("stats", "mcollective").yields(@util.create_response("node1", {:value => "1"}, {:total => 0, :replies => 0, :validated => 0, :unvalidated => 0, :filtered => 0, :passed => 0}))
                @app.expects(:printf).with("%40s> total=%d, replies=%d, valid=%d, invalid=%d, filtered=%d, passed=%d\n", "node1", 0, 0, 0, 0, 0, 0)
                @app.main
            end
        end
    end
end

