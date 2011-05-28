module MCTestHelper
    def create_facts_mock(factsource)
        facts = Mocha::Mock.new
        facts.stubs(:get_facts).returns(factsource)

        factsource.each_pair do |k, v|
            facts.stubs(:get_fact).with(k).returns(v)
        end

        MCollective::PluginManager << {:type => "facts_plugin", :class => facts, :single_instance => false}
    end

    def create_config_mock(config)
        cfg = Mocha::Mock.new
        cfg.stubs(:configured).returns(true)
        cfg.stubs(:rpcauthorization).returns(false)
        cfg.stubs(:main_collective).returns("mcollective")
        cfg.stubs(:collectives).returns(["production", "staging"])
        cfg.stubs(:classesfile).returns("classes.txt")
        cfg.stubs(:identity).returns("rspec_tests")

        config.each_pair do |k, v|
            cfg.send(:stubs, k).returns(v)
        end

        if config.include?(:libdir)
            [config[:libdir]].flatten.each do |dir|
                $: << dir if File.exist?(dir)
            end
        end

        MCollective::Config.stubs(:instance).returns(cfg)

        cfg
    end

    def create_logger_mock
        logger = Mocha::Mock.new(:logger)

        [:log, :start, :debug, :info, :warn].each do |meth|
            logger.stubs(meth)
        end

        MCollective::Log.configure(logger)

        logger
    end

    def create_connector_mock
        connector = Mocha::Mock.new(:connector)

        [:connect, :receive, :publish, :subscribe, :unsubscribe, :disconnect].each do |meth|
            connector.stubs(meth)
        end

        MCollective::PluginManager << {:type => "connector_plugin", :class => connector}

        connector
    end

    def load_agent(agent)
        classname = "MCollective::Agent::#{agent.capitalize}"
        MCollective::PluginManager.delete("#{agent}_agent")
        MCollective::PluginManager.loadclass(classname)
        MCollective::PluginManager << {:type => "#{agent}_agent", :class => classname, :single_instance => false}
        MCollective::PluginManager["#{agent}_agent"]
    end
end

