#! /usr/bin/env ruby

require File.join([File.dirname(__FILE__), '/../../spec_helper'])

module MCollective
    describe "facts aplication" do
        before do
            @util = MCollective::Test::ApplicationTest.new("facts", :config => {:libdir => "/usr/libexec/mcollective"})
            @app = @util.plugin
        end

        describe "#application_description" do
            it "should have a description set" do
                @app.should have_a_description
            end
        end

        describe "#post_option_parser" do
            it "should set a fact configuration" do
                ARGV << "test"

                configuration = {}

                @app.post_option_parser(configuration)
                configuration[:fact].should == "test"
            end
        end

        describe "#validate_configuration" do
            it "should fail for missing fact" do
                expect {
                    @app.validate_configuration({})
                }.to raise_error("Please specify a fact to report for")
            end

            it "should not fail if a fact is given" do
                @app.validate_configuration({:fact => "foo"})
            end
        end

        describe "#show_single_fact_report" do
            it "should show a non verbose report by default" do
                @app.expects(:puts).with(regexp_matches(/node1/)).never
                @app.show_single_fact_report("foo", {"foo" => ["node1", "node2"]})
            end

            it "should support verbose reports" do
                @app.expects(:puts).with(regexp_matches(/node1/)).once
                @app.show_single_fact_report("foo", {"foo" => ["node1", "node2"]}, true)
            end
        end

        describe "#main" do
            it "should handle failure responses correctly" do
                STDERR.expects(:puts).with("Could not parse facts for node2: NoMethodError: undefined method `[]' for nil:NilClass")

                @app.expects(:configuration).returns({:fact => "test"}).twice
                @app.expects(:options).returns({})

                rpcutil = @app.create_client("rpcutil") do |client|
                    resp1 = @util.create_response("node1", :value => "1")
                    resp2 = @util.create_response("node2", nil)
                    client.expects(:get_fact).with(:fact => "test").multiple_yields([resp1], [resp2])
                end

                @app.expects(:show_single_fact_report).with("test", {"1" => ["node1"]}, nil)
                @app.expects(:printrpcstats).once

                @app.main
            end

            it "should parse responses correctly" do
                @app.expects(:configuration).returns({:fact => "test"}).twice
                @app.expects(:options).returns({})

                rpcutil = @app.create_client("rpcutil") do |client|
                    resp1 = @util.create_response("node1", :value => "1")
                    resp2 = @util.create_response("node2", :value => "2")
                    client.expects(:get_fact).with(:fact => "test").multiple_yields([resp1], [resp2])
                end

                @app.expects(:show_single_fact_report).with("test", {"1" => ["node1"], "2" => ["node2"]}, nil)
                @app.expects(:printrpcstats).once

                @app.main
            end
        end
    end
end
