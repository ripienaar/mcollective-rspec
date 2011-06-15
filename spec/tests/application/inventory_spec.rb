#! /usr/bin/env ruby

require File.join([File.dirname(__FILE__), '/../../spec_helper'])

module FormatR
    class Format
    end
end

module MCollecitve
    describe "inventory application" do
        before do
            @util = MCollective::Test::ApplicationTest.new("inventory", :config => {:libdir => "/usr/libexec/mcollective"})
            @app = @util.plugin
        end

        describe "#application_description" do
            it "should have a description set" do
                @app.should have_a_description
            end
        end

        describe "#post_option_parser" do
            it "should set a node" do
                ARGV << "test"

                configuration = {}
                @app.post_option_parser(configuration)
                configuration[:node].should == "test"
            end
        end

        describe "#validate_configuration" do
            it "should validate that node, script, collectives or collectivemap is set" do
                configuration = {:node => "node1"}
                @app.validate_configuration(configuration)
            end

            it "should raise and exception if none of node, script, collectives or collectivemap is set" do
                configuration = {}
                expect{
                    @app.validate_configuration(configuration)
                }.to raise_error "Need to specify either a node name, script to run or other options"
            end
        end

        describe "#main" do
            it "should execute a script if it is defined in configuration" do
                @app.expects(:configuration).times(3).returns(:script => "test")
                File.expects(:exist?).with("test").returns(true)
                File.expects(:read).with("test")
                @app.expects(:eval)

                @app.main
            end

            it "should raise an exception if it could not find the script" do
                @app.expects(:configuration).twice.returns({:script => "test"})
                File.expects(:exist?).with("test").returns(false)
                @app.expects(:configuration).returns(:script => "test")

                expect{
                    @app.main
                }.to raise_error("Could not find script to run: test")
            end

            it "should call collectives_map if configuraion contains collectivemap" do
                @app.stubs(:configuration).returns(:collectivemap => "test")
                @app.expects(:collectives_map).with("test")
                @app.main
            end

            it "should call collectives_report if configuration contains collectives" do
                @app.stubs(:configuration).returns(:collectives => "test")
                @app.expects(:collectives_report)
                @app.main
            end

            it "should call node_inventory if configuration doesn't include script, collectivemap or collectives" do
                @app.stubs(:configuration).returns({})
                @app.expects(:node_inventory)
                @app.main
            end
        end

        describe "#collectives_map" do
           it "should create a DOT graph of the collectives" do
                @app.stubs(:configuration).returns(:collectivemap => "test_collective")
                graph_mock = mock
                graph_mock.stubs(:puts)

                File.expects(:open).with("test_collective", "w").yields(graph_mock)
                @app.expects(:get_collectives).returns({:collectives => {:collective1 => ["node1"], :collective2 => ["node2"]}})
                @app.main
           end
        end

        describe "#get_collectives" do
           it "should return a list of collectives" do
                @app.stubs(:configuration).returns(:collectivemap => "test_collective")
                graph_mock = mock
                graph_mock.stubs(:puts)
                rpcutil_mock = mock

                File.expects(:open).with("test_collective", "w").yields(graph_mock)

                @app.expects(:rpcclient).with("rpcutil").returns(rpcutil_mock)
                rpcutil_mock.expects(:progress=).with(false)
                rpcutil_mock.expects(:collective_info).yields("", {:data => {:collectives => ["collective1", "collective2"]}, :sender => "node1"})
                @app.main
           end
        end

        describe "#collectives_report" do
           it "should print all the collectives and the number on nodes on each and the total amount of nodes" do
                @app.stubs(:configuration).returns(:collectives => "test")
                @app.expects(:get_collectives).returns({:collectives => {"collective1" => ["node1"], "collective2" => ["node2"]}, :nodes => 2, :total_nodes => 2 })
                @app.expects(:puts).with("   %-30s %d" % [ "collective1", 1 ])
                @app.expects(:puts).with("   %-30s %d" % [ "collective2", 1 ])
                @app.expects(:puts).with("   %30s %d" % [ "Total nodes:", 2 ])
                @app.main
           end
        end

        describe "#node_inventory" do
           it "should raise an exception if it cannnot retrieve stats from the node" do
                rpcclient_mock = mock

                @app.stubs(:configuration).returns({:node => "test"})
                @app.expects(:rpcclient).with("rpcutil").returns(rpcclient_mock)

                rpcclient_mock.expects(:identity_filter).with("test")
                rpcclient_mock.expects(:progress=).with(false)
                rpcclient_mock.expects(:custom_request).with("daemon_stats", {}, "test", {"identity" => "test"}).returns([{:statuscode => 1, :statusmsg => "RPC ABORTED"}])
                STDERR.expects(:puts).with("Failed to retrieve daemon_stats from test: RPC ABORTED")
                @app.main
           end

           it "should display and error message if it cannot retrieve the inventory for a node" do
                rpcclient_mock = mock

                @app.stubs(:configuration).returns({:node => "test"})
                @app.expects(:rpcclient).with("rpcutil").returns(rpcclient_mock)
                rpcclient_mock.expects(:identity_filter).with("test")
                rpcclient_mock.expects(:progress=).with(false)
                rpcclient_mock.expects(:custom_request).with("daemon_stats", {}, "test", {"identity" => "test"}).returns([:statuscode => 0])
                rpcclient_mock.expects(:custom_request).with("inventory", {}, "test", {"identity" => "test"}).returns([{:statuscode => 1, :statusmsg => "RPC ABORTED"}])
                STDERR.expects(:puts).with("Failed to retrieve inventory for test: RPC ABORTED")
                @app.main
           end

           it "should print an error message if an exception is raised" do
               rpcclient_mock = mock

                @app.stubs(:configuration).returns({:node => "test"})
                @app.expects(:rpcclient).with("rpcutil").returns(rpcclient_mock)
                rpcclient_mock.expects(:identity_filter).with("test")
                rpcclient_mock.expects(:progress=).with(false)
                rpcclient_mock.expects(:custom_request).with("daemon_stats", {}, "test", {"identity" => "test"}).returns([:statuscode => 0])
                rpcclient_mock.expects(:custom_request).with("inventory", {}, "test", {"identity" => "test"}).returns([{:statuscode => 0, :statusmsg => "SUCCESS", :data => "", :sender => "test"}])
                @app.expects(:puts).with("Inventory for test:").raises(Exception, "ERROR")
                STDERR.expects(:puts).with("Failed to display node inventory: Exception: ERROR")
                @app.main
           end

           it "should display node inventory and succeed if no agents, classes or facts are present" do
                rpcclient_mock = mock

                node_data = {:version => "version",
                             :starttime => Time.now,
                             :configfile => "configfile",
                             :pid => "pid",
                             :total => "total",
                             :passed => "passed",
                             :filtered => "filtered",
                             :replies => "replies",
                             :times => {:utime => 1, :stime => 1}
                            }
                response_data = {:classes => [],
                                 :agents => [],
                                 :facts => []}

                @app.stubs(:configuration).returns({:node => "test"})
                @app.expects(:rpcclient).with("rpcutil").returns(rpcclient_mock)
                rpcclient_mock.expects(:identity_filter).with("test")
                rpcclient_mock.expects(:progress=).with(false)
                rpcclient_mock.expects(:custom_request).with("daemon_stats", {}, "test", {"identity" => "test"}).returns([{:statuscode => 0, :data => node_data}])
                rpcclient_mock.expects(:custom_request).with("inventory", {}, "test", {"identity" => "test"}).returns([{:statuscode => 0, :statusmsg => "SUCCESS", :data => response_data, :sender => "test"}])
                @app.expects(:puts).with("      No agents installed")
                @app.expects(:puts).with("      No classes applied")
                @app.expects(:puts).with("      No facts known")

                @app.main
           end

           it "should display node inventory with agents, class and facts" do
                rpcclient_mock = mock

                node_data = {:version => "version",
                             :starttime => Time.now,
                             :configfile => "configfile",
                             :pid => "pid",
                             :total => "total",
                             :passed => "passed",
                             :filtered => "filtered",
                             :replies => "replies",
                             :times => {:utime => 1, :stime => 1}
                            }
                response_data = {:classes => ["class"],
                                 :agents => ["agent"],
                                 :facts => ["fact"]}

                @app.stubs(:configuration).returns({:node => "test"})
                @app.expects(:rpcclient).with("rpcutil").returns(rpcclient_mock)
                rpcclient_mock.expects(:identity_filter).with("test")
                rpcclient_mock.expects(:progress=).with(false)
                rpcclient_mock.expects(:custom_request).with("daemon_stats", {}, "test", {"identity" => "test"}).returns([{:statuscode => 0, :data => node_data}])
                rpcclient_mock.expects(:custom_request).with("inventory", {}, "test", {"identity" => "test"}).returns([{:statuscode => 0, :statusmsg => "SUCCESS", :data => response_data, :sender => "test"}])
                Array.any_instance.expects(:in_groups_of).with(3, "")
                Array.any_instance.expects(:in_groups_of).with(2, "")
                Array.any_instance.expects(:sort_by).returns(["fact"])
                @app.main
           end
        end

        describe "#inventory" do
            it "should raise an exception if no block is given" do
                expect{
                    @app.inventory
                }.to raise_error "Need to give a block to inventory"
            end

            it "should raise an exception if ftm is not set" do
                expect{
                    @app.inventory do |t, resp|

                    end
                }.to raise_error "Need to define a format"
            end

            it "should raise an exception if flds is not set" do
                @app.format "test"
                expect{
                    @app.inventory do |t, resp|
                    end
                }.to raise_error "Need to define inventory fields"
            end

            it "should print and inventory" do
                rpcclient_mock = mock

                @app.expects(:rpcclient).with("rpcutil").returns(rpcclient_mock)
                rpcclient_mock.expects(:progress=).with(false)
                rpcclient_mock.expects(:inventory).yields("", {:sender => "node1", :data => {:facts => "facts", :classes => "classes", :agents => "agents"}})
                @app

                @app.inventory do |t, resp|
                    @app.format "%s:\t\t%s\t\t%s"
                    @app.fields { ["field1", "field2", "field3"]}
                end
            end
        end

        describe "#formatted_inventory" do
            before do
                @app.expects(:require).with('formatr')
            end

            it "should raise an exception if no block is given" do
                STDERR.expects(:puts).with("Could not create report: RuntimeError: Need to give a block to formatted_inventory")
                expect{
                    @app.formatted_inventory
                }.to raise_error "exit"
            end

            it "should raise exception if page body format is not defined" do
                STDERR.expects(:puts).with("Could not create report: RuntimeError: Need to define page body format")
                expect{
                    @app.formatted_inventory do |t, resp|
                    end
                }.to raise_error "exit"
            end

            it "should print an inventory" do
                body_mock = mock
                rpcclient_mock = mock

                FormatR::Format.expects(:new).with("A page heading", "A page body").returns(body_mock)
                body_mock.expects(:setPageLength).with(10)
                @app.expects(:rpcclient).with("rpcutil").returns(rpcclient_mock)
                rpcclient_mock.expects(:progress=).with(false)
                body_mock.expects(:printFormat)
                rpcclient_mock.expects(:inventory).yields("", {:sender => "node1", :data => {:facts => "facts", :classes => "classes", :agents => "agents"}})

                @app.formatted_inventory do |t, resp|
                    @app.page_heading "A page heading"
                    @app.page_body "A page body"
                    @app.page_length 10
                end
            end
        end

        describe "Array#in_groups_of" do
            it "should yield groups as arrays" do
                test_array = [1,2,3,4,5,6]
                test_array.in_groups_of(2, "")[0].should == [1,2]
                test_array.in_groups_of(3, "")[1].should == [4,5,6]
            end
        end

    end
end
