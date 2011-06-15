#! /usr/bin/env ruby

require File.join([File.dirname(__FILE__), '/../../spec_helper'])

module MCollective
    describe "rpc application" do
        before do
            @util = MCollective::Test::ApplicationTest.new("rpc", :config => {:libdir => "/usr/libexec/mcollective"})
            @app = @util.plugin
        end

        describe "#application_description" do
            it "should have a description set" do
                @app.should have_a_description
            end
        end

        describe "#post_option_parser" do
            it "should termiate with error if agent and action are not both specified and commandline arguments are less than two" do
                STDERR.expects(:puts).with("No agent, action and arguments specified")
                @app.expects(:exit!).raises("exit")
                expect{
                    @app.post_option_parser({})
                }.to raise_error "exit"
            end

            it "should display an error message if agent and action are not both defined and commandline arguments do not match the given regex" do
                ARGV << "agent"
                ARGV << "action"
                ARGV << "args"
                STDERR.expects(:puts).with("Could not parse --arg args")
                @app.post_option_parser({:agent => "agent", :arguments => "args"})
            end

            it "should cast strings to symbols if agent, action and arguments are defined in configuration" do
                configuration = {:agent => "agent",
                                 :action => "action",
                                 :arguments => ["arg1=foo"]
                }
                @app.post_option_parser(configuration)
                configuration[:arguments].keys.first.class.should == Symbol
            end

            it "should process arguments and cast the string to symbols if agent and action are not both defined and there are two or more command line arguments" do
                ARGV << "agent"
                ARGV << "action"
                ARGV << "arg1=foo"
                configuration = {}

                @app.post_option_parser(configuration)
                configuration[:arguments].keys.first.class.should == Symbol
            end
        end

        describe "#booleanish_to_boolean" do
            it "should set argument to true for 'true', 'yes' and '1'" do
                arguments = {:arg1 => "true",
                             :arg2 => "yes",
                             :arg3 => "1"
                }
                ddl = {:input => {:arg1 => {:type => :boolean},
                                  :arg2 => {:type => :boolean},
                                  :arg3 => {:type => :boolean}}
                }
                @app.booleanish_to_boolean(arguments, ddl)
                arguments.each do |k, v|
                    v.should be_true
                end
            end

            it "should set argument to false for 'false', 'no' and '0'" do
                arguments = {:arg1 => "false",
                             :arg2 => "no",
                             :arg3 => "0"
                }
                ddl = {:input => {:arg1 => {:type => :boolean},
                                  :arg2 => {:type => :boolean},
                                  :arg3 => {:type => :boolean}}
                }
                @app.booleanish_to_boolean(arguments, ddl)
                arguments.each do |k, v|
                    v.should be_false
                end
            end

            it "should return true if an exception is raised" do
                arguments = {:arg1 => "true"}
                a = @app.booleanish_to_boolean(arguments, {})
                a.should be_true
            end
        end

        describe "#main" do
            it "should make the rpc call and not display results if no_results is set in configuration" do
                rpcclient_mock = mock

                @app.stubs(:configuration).returns({:no_results => true, :arguments => {:arg1 => "argument1", :process_results => false},  :agent => "agent", :action => "action"})
                @app.expects(:rpcclient).with("agent").returns(rpcclient_mock)
                rpcclient_mock.expects(:ddl).returns(nil)
                rpcclient_mock.expects(:agent_filter).with("agent")
                rpcclient_mock.expects(:send).with("action", {:arg1 => "argument1", :process_results => false}).returns("id")
                @app.expects(:puts).with("Request sent with id: id")
                @app.main
            end

            it "should make the rpc call and display results if no_results is not set in configuration" do
                rpcclient_mock = mock

                @app.stubs(:configuration).returns({:agent => "agent", :action => "action", :arguments => {:arg1 => "argument1"}})
                @app.expects(:rpcclient).with("agent").returns(rpcclient_mock)
                rpcclient_mock.expects(:ddl).returns(nil)
                rpcclient_mock.expects(:agent_filter).with("agent")
                rpcclient_mock.expects(:discover).with({:verbose => true})
                rpcclient_mock.expects(:send).with("action", {:arg1 => "argument1"}).returns("id")
                @app.expects(:printrpc).with("id")
                @app.expects(:printrpcstats).with({:caption => "agent#action call stats"})
                @app.main
            end
        end
    end
end
