module Matchers
    def have_data_items(*items); RPCResultItems.new(items); end

    class RPCResultItems
        def initialize(expected)
            @expected = expected.flatten.sort
        end

        def matches?(actual)
            @actual = actual[:data].keys.sort
            @actual == @expected
        end

        def failure_message
            "expected keys '#{@expected.join ', '}' but got '#{@actual.join ', '}'"
        end

        def negative_failure_message
            "did not expect keys '#{@expected.join ', '}' but got '#{@actual.keys.join ', '}'"
        end
    end

    class RPCMetadata
        def matches?(actual)
            @msg = "Unknown error"

            [:name, :description, :author, :license, :version, :url, :timeout].each do |item|
                unless actual.include?(item)
                    @msg = "needs a '#{item}' item"
                    return false
                end
            end

            [:name, :description, :author, :license, :version, :url].each do |item|
                unless actual[item].is_a?(String)
                    @msg = "#{item} should be a string"
                    return false
                end
            end

            unless actual[:timeout].is_a?(Numeric)
                @msg = "timeout should be numeric"
                return false
            end

            return true
        end

        def failure_message
            "Invalid meta data: #{@msg}"
        end
    end
end
