#! /usr/bin/env ruby

require File.join([File.dirname(__FILE__), '/../../spec_helper'])

module MCollective

    describe "Ping application" do
        before do
            @util = MCollective::Test::ApplicationTest.new("ping", :config => {:libdir => "/usr/libexec/mcollective"})
            @app = @util.plugin
        end

        describe "#application_description" do
            it "should have an application description set" do
                @app.should have_a_description
            end
        end

        describe "#main" do
            it "should display ping results if there are responses" do
                mock_client = mock
                mock_client.stubs(:options=)
                @app.stubs(:options).returns(:config => "config")

                MCollective::Client.expects(:new).returns(mock_client)
                mock_client.expects(:req).with("ping", "discovery").yields(@util.create_response("node1", :value => "1"))
                @app.expects(:printf).twice

                @app.main
            end

            it "should not display messages if there are no responses" do
                mock_client = mock
                mock_client.stubs(:options=)
                @app.stubs(:options).returns(:config => "config")

                MCollective::Client.expects(:new).returns(mock_client)
                mock_client.expects(:req).with("ping", "discovery")
                @app.expects(:puts).with("No responses received")

                @app.main
            end
        end

    end
end
