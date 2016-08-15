require 'audited/audit'

# Only useful for testing.
module Audited
  module Async
    class Synchronous
      def self.enqueue(klass, audits_attrs)
        klass = Module.const_get(klass_name)
        audits_attrs.each do |attrs|
          klass.create(attrs)
        end
      end
    end
  end
end
