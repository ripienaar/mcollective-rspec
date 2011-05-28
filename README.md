A unit testing system for MCollective Agents that can
run agents without the need for a running mcollectived
or middleware.

Given the agent below:

<pre>
module MCollective
  module Agent
    class Echo&lt;RPC::Agent
      action "echo" do
        validate :msg, String

        reply[:msg] = request[:msg]
        reply[:time] = Time.now.to_s
      end
    end
  end
end
</pre>

You can easily test it using the test case below:

<pre>
describe "rpcutil agent" do
  before do
    # Load the 'echo' agent from the libdir provided
    @agent = LocalAgentTest.new("echo", :config => {:libdir => "/usr/libexec/mcollective"})
  end

  describe "#echo" do
    it "should only allow strings to be used" do
      result = @agent.call(:echo, {:msg => 1})

      # Many matchers exist for the response status like
      # be_successful, be_invalid_data_error etc
      result.should be_unknown_error
    end

    it "should send back a correct echo action" do
      # The agent does Time.now which we cannot
      # really test for, mock it so it returns known data
      Time.expects(:now).returns(0)

      result = @agent.call(:echo, {:msg => "hello world"})
      result.should be_successful

      # makes sure all the result data is there
      result.should have_data_items(:msg, :time)

      # check the result for validity
      result[:data][:msg].should == "hello world"
      result[:data][:time].should == 0
      end
  end
end
</pre>

A more complete example for the rpcutil agent can be found in the
spec directory

Running the rpcutil test results in the following output:

<pre>
rpcutil agent
  #meta
    should have valid metadata
  #agent_inventory
    should correctly report the agent inventory
  #inventory
    should return the correct inventory
  #get_fact
    should fail for non string fact names
    should look up a single fact
  #get_config_item
    should validate that a string was passed
    should fail for unknown config items
    should return valid config data
  #collective_info
    should report correct collective data
  #ping
    should return the correct local time
  #daemon_stats
    should return correct stats

Finished in 0.09804 seconds
11 examples, 0 failures
</pre>
