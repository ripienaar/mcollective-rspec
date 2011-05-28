class LocalAgentTest
    attr_reader :config, :logger, :agent, :connector, :plugin, :facts

    include MCTestHelper
    include MCollective::RPC

    def initialize(agent, options={})
        config = options[:config]
        facts = options[:facts] || {"fact" => "value"}

        @config = create_config_mock(config)
        @agent = agent.to_s
        @logger = create_logger_mock
        @connector = create_connector_mock
        @plugin = load_agent(agent)

        create_facts_mock(facts)
    end

    def run_action(agent, action, args)
    end

    def call(action, args={})
        request = {:action => action.to_s,
                   :agent => agent,
                   :data => args}

        @plugin.handlemsg({:body => request}, connector)
    end
end
