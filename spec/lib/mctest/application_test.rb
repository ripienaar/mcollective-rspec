module MCTest
    class ApplicationTest
        attr_reader :config, :logger, :application, :plugin

        include MCTest::Util

        def initialize(application, options={})
            config = options[:config] || {}
            facts = options[:facts] || {"fact" => "value"}

            ARGV.clear

            @config = create_config_mock(config)
            @application = application.to_s
            @logger = create_logger_mock
            @plugin = load_application(@application)

            @plugin.stubs(:printrpcstats)
            @plugin.stubs(:puts)
            @plugin.stubs(:printf)

            make_create_client
        end
        
        def make_create_client
            @plugin.instance_eval "
                def create_client(client)
                    mock_client = Mocha::Mock.new
                    mock_client.stubs(:progress=)
                    mock_client.stubs(:progress)

                    yield(mock_client) if block_given?

                    MCollective::Application::Facts.any_instance.expects(:rpcclient).with(client).returns(mock_client)

                    mock_client
                end
            "
        end
    end
end
