#! /usr/bin/env ruby

require File.join([File.dirname(__FILE__), '/../../spec_helper'])

module MCollective
    describe "help application" do
        before do
            @util = MCollective::Test::ApplicationTest.new("help", :config => {:libdir => "/usr/libexec/mcollective"})
            @app = @util.plugin
        end

        describe "#application_description" do
            it "should have a description set" do
                @app.should have_a_description
            end
        end

        describe "#post_option_parser" do
            it "should set an agent" do
                ARGV << "test"

                configuration = {}
                @app.post_option_parser(configuration)
                configuration[:agent].should == "test"
            end
        end

        describe "#main" do
            it "should display ddl based help if the agent exists" do
                @app.expects(:configuration).twice.returns(:agent => "test")
                ddl = mock
                MCollective::RPC::DDL.expects(:new).with("test").returns(ddl)
                @util.config.expects(:rpchelptemplate)
                @app.expects(:puts)
                ddl.expects(:help)

                @app.main
            end

            it "should display a list of all agents if agent does not exist" do
                app_mock = mock
                app_array = ["test"]

                @app.expects(:configuration).returns({})
                ::MCollective.expects(:version)
                Applications.expects(:list).returns(app_array)
                Applications.expects(:[]).with("test").returns(app_mock)
                app_mock.expects(:application_description)

                @app.main
            end
        end
    end
end
