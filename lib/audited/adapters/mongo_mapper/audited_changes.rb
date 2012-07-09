module Audited
  module Adapters
    module MongoMapper
      class AuditedChanges < ::Hash
        def self.from_mongo(changes)
          changes.is_a?(Hash) ? new.replace(changes) : changes
        end

        def self.to_mongo(changes)
          if changes.is_a?(Hash)
            changes.inject({}) do |memo, (key, value)|
              memo[key] = if value.is_a?(Array)
                value.map{|v| v.class.to_mongo(v) }
              else
                value
              end
              memo
            end
          else
            changes
          end
        end
      end
    end
  end
end
