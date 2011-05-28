module Matchers
    def be_valid_metadata; RPCMetadata.new; end

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

