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
end
