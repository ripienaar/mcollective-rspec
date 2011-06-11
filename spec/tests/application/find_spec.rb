#! /usr/bin/env ruby

require File.join([File.dirname(__FILE__), '/../../spec_helper'])

module MCollective

    describe "find application" do
        before do
            @util = MCollective::Test::ApplicationTest.new("find", :config => {:libdir => "/usr/libexec/mcollective"})
            @app = @util.plugin
        end

        describe "#application_description" do
            it "should have a description set" do
                @app.should have_a_description
            end
        end

        describe "#main" do
            it "should not display stats if verbose is set to false" do
                mock_client = mock
                mock_client.stubs(:options=)
                @app.stubs(:options).returns(:client => "", :verbose => false)

                MCollective::Client.expects(:new).returns(mock_client)
                mock_client.expects(:req).with("ping", "discovery").yields(@util.create_response("node1", :value => "1"))
                @app.main
            end

            it "should display stats if verbose is set to true" do
                mock_client = mock
                mock_client.stubs(:options=)
                @app.stubs(:options).returns(:client => "", :verbose => true)

                MCollective::Client.expects(:new).returns(mock_client)
                mock_client.expects(:req).with("ping", "discovery").yields(@util.create_response("node1", :value => "1"))
                mock_client.expects(:display_stats).returns(true)
                @app.main
            end
        end
    end
end
