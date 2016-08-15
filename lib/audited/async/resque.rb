module Audited
  module Async
    class Resque
      @queue = :audit

      # Allow override in initializer
      def self.queue=(queue)
        @queue = queue.to_sym
      end

      def self.enqueue(klass_name, audits_attrs)
        Resque.enqueue(self, klass_name, audits_attrs)
      end

      # Takes a model `klass` and an array of hashes of audit `attrs` and
      # creates audit records from them.
      def self.perform(klass_name, audits_attrs)
        klass = Module.const_get(klass_name)
        audits_attrs.each do |attrs|
          klass.create(attrs)
        end
      end
    end
  end
end
