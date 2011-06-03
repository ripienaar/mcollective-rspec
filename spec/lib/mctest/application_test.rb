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

            @plugin.stubs(:puts)
            @plugin.stubs(:printf)
            @plugin.stubs(:printrpcstats)
        end

        def self.create_response(senderid, value = 1, fail = false)
            unless fail
                {:senderid => senderid, :body => {:data => {:value => value}}}
            else
                {:senderid => senderid, :body => nil}
            end
        end
    end
end
