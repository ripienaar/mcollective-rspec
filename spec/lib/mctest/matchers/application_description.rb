module MCTest
    module Matchers
        def have_a_description(description=nil); ApplicationDescription.new(description); end

        class ApplicationDescription
            def initialize(match=nil)
                @match = match
            end

            def matches?(actual)
                @actual = actual.application_description

                if @match
                    return @actual == @match
                else
                    return !@actual.nil?
                end
            end

            def failure_message
                if @match
                    "application should have a description '#{@match}' but got '#{@actual}'"
                else
                    "application should have a description, got #{@match}"
                end
            end

            def negative_failure_message
                if @match
                    "application should not have a description matching '#{@match}' but got '#{@actual}'"
                else
                    "application should not have a description"
                end
            end
        end
    end
end
