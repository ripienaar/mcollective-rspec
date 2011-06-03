#! /usr/bin/env ruby

require File.join([File.dirname(__FILE__), '/../../spec_helper'])

module MCollective
    describe "facts aplication" do
        before do
            ARGV.clear

            $: << "/home/rip/.mcollective.d/lib"
            PluginManager.delete("facts_application")
            PluginManager.loadclass("MCollective::Application::Facts")

            @app = MCollective::Application::Facts.new
        end

        describe "#application_description" do
            it "should have a description set" do
                @app.application_description.should_not == nil
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
                @app.stubs(:puts)
                @app.stubs(:printf)
                @app.expects(:puts).with(regexp_matches(/node1/)).never
                @app.show_single_fact_report("foo", {"foo" => ["node1", "node2"]})
            end

            it "should support verbose reports" do
                @app.stubs(:puts)
                @app.stubs(:printf)
                @app.expects(:puts).with(regexp_matches(/node1/)).once
                @app.show_single_fact_report("foo", {"foo" => ["node1", "node2"]}, true)
            end
        end

        describe "#main" do
            it "should handle failure responses correctly" do
                resp1 = {:senderid => "node1", :body => {:data => {:value => "1"}}}
                resp2 = {:senderid => "node2", :body => nil}

                STDERR.expects(:puts).with("Could not parse facts for node2: NoMethodError: undefined method `[]' for nil:NilClass")

                @app.expects(:configuration).returns({:fact => "test"}).twice
                @app.expects(:options).returns({})

                rpcutil = mock
                rpcutil.expects(:progress=).once
                rpcutil.expects(:get_fact).with(:fact => "test").multiple_yields([resp1], [resp2])
                @app.expects(:rpcclient).with("rpcutil").returns(rpcutil)

                @app.expects(:show_single_fact_report).with("test", {"1" => ["node1"]}, nil)
                @app.expects(:printrpcstats).once

                @app.main
            end

            it "should parse responses correctly" do
                resp1 = {:senderid => "node1", :body => {:data => {:value => "1"}}}
                resp2 = {:senderid => "node2", :body => {:data => {:value => "2"}}}

                @app.expects(:configuration).returns({:fact => "test"}).twice
                @app.expects(:options).returns({})

                rpcutil = mock
                rpcutil.expects(:progress=).once
                rpcutil.expects(:get_fact).with(:fact => "test").multiple_yields([resp1], [resp2])
                @app.expects(:rpcclient).with("rpcutil").returns(rpcutil)

                @app.expects(:show_single_fact_report).with("test", {"1" => ["node1"], "2" => ["node2"]}, nil)
                @app.expects(:printrpcstats).once

                @app.main
            end
        end
    end
end
