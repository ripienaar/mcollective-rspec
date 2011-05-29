#!/usr/bin/env ruby

require File.join([File.dirname(__FILE__), '/../spec_helper'])

describe "rpcutil agent" do
    before do
        @agent = MCTest::LocalAgentTest.new("rpcutil", :config => {:libdir => "/usr/libexec/mcollective"})
    end

    describe "#meta" do
        it "should have valid metadata" do
            @agent.plugin.meta.should be_valid_metadata
        end
    end

    describe "#agent_inventory" do
        it "should correctly report the agent inventory" do
            MCollective::Agents.expects(:agentlist).returns(["rpcutil"])
            result = @agent.call(:agent_inventory)

            result.should be_successful
            result.should have_data_items(:agents)
        end
    end

    describe "#inventory" do
        it "should return the correct inventory" do
            MCollective::Agents.expects(:agentlist).returns(["rpcutil"])
            File.stubs("exist?").with("classes.txt").returns(true)
            File.stubs(:readlines).with("classes.txt").returns(["class1", "class2"])

            result = @agent.call(:inventory)
            result.should be_successful
            result.should have_data_items(:classes, :main_collective, :collectives, :facts, :agents, :version)
        end
    end

    describe "#get_fact" do
        it "should fail for non string fact names" do
            result = @agent.call(:get_fact, {:fact => 1})
            result.should be_unknown_error
        end

        it "should look up a single fact" do
            result = @agent.call(:get_fact, {:fact => "fact"})
            result.should be_successful
            result.should have_data_items(:fact, :value)
        end
    end

    describe "#get_config_item" do
        it "should validate that a string was passed" do
            result = @agent.call(:get_config_item, {:item => 1})
            result.should be_unknown_error
        end

        it "should fail for unknown config items" do
            result = @agent.call(:get_config_item, {:item => "nosuchitem"})

            result.should be_aborted_error
            result[:statusmsg].should == "Unknown config property nosuchitem"
        end

        it "should return valid config data" do
            result = @agent.call(:get_config_item, {:item => "identity"})
            result.should be_successful
            result.should have_data_items(:item, :value)
            result[:data].should == {:item => "identity", :value => "rspec_tests"}
        end
    end

    describe "#collective_info" do
        it "should report correct collective data" do
            result = @agent.call(:collective_info)
            result.should be_successful
            result.should have_data_items(:collectives, :main_collective)

            result[:data][:main_collective].should == "mcollective"
            result[:data][:collectives].should == ["production", "staging"]
        end
    end

    describe "#ping" do
        it "should return the correct local time" do
            Time.expects(:now).returns(0)
            result = @agent.call(:ping)
            result.should be_successful
            result.should have_data_items(:pong)
            result[:data][:pong].should == 0
        end
    end

    describe "#daemon_stats" do
        it "should return correct stats" do
            stats = mock
            stats.expects(:to_hash).returns({:threads => :threads,
                                             :agents => :agents,
                                             :pid => :pid,
                                             :times => :times,
                                             :stats => {}})

            MCollective::PluginManager << {:type => "global_stats", :class => stats, :single_instance => false}

            @agent.config.expects(:configfile).returns("server.cfg")
            MCollective.expects(:version).returns("version")

            result = @agent.call(:daemon_stats)
            result.should be_successful
            result.should have_data_items(:configfile, :times, :threads, :pid, :agents, :version)

            result[:data].should == {:configfile=>"server.cfg",
                                     :times=>:times,
                                     :threads=>:threads,
                                     :pid=>:pid,
                                     :agents=>:agents,
                                     :version=>"version"}
        end
    end
end
