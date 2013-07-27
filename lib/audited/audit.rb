module Audited
  module Audit
    def self.included(klass)
      klass.extend(ClassMethods)
      klass.setup_audit
    end

    module ClassMethods
      def setup_audit
        belongs_to :auditable,  :polymorphic => true
        belongs_to :user,       :polymorphic => true
        belongs_to :associated, :polymorphic => true

        before_create :set_version_number, :set_audit_user

        cattr_accessor :audited_class_names
        self.audited_class_names = Set.new
      end

      # Returns the list of classes that are being audited
      def audited_classes
        audited_class_names.map(&:constantize)
      end

      # All audits made during the block called will be recorded as made
      # by +user+. This method is hopefully threadsafe, making it ideal
      # for background operations that require audit information.
      def as_user(user, &block)
        Thread.current[:audited_user] = user
        yield
      ensure
        Thread.current[:audited_user] = nil
      end

      # @private
      def reconstruct_attributes(audits)
        attributes = {}
        result = audits.collect do |audit|
          attributes.merge!(audit.new_attributes).merge!(:version => audit.version)
          yield attributes if block_given?
        end
        block_given? ? result : attributes
      end

      # @private
      def assign_revision_attributes(record, attributes)
        attributes.each do |attr, val|
          record = record.dup if record.frozen?

          if record.respond_to?("#{attr}=")
            record.attributes.has_key?(attr.to_s) ?
              record[attr] = val :
              record.send("#{attr}=", val)
          end
        end
        record
      end
    end

    # Return an instance of what the object looked like at this revision. If
    # the object has been destroyed, this will be a new record.
    def revision
      clazz = auditable_type.constantize
      (clazz.find_by_id(auditable_id) || clazz.new).tap do |m|
        self.class.assign_revision_attributes(m, self.class.reconstruct_attributes(ancestors).merge({ :version => version }))
      end
    end

    # Returns a hash of the changed attributes with the new values
    def new_attributes
      (audited_changes || {}).inject({}.with_indifferent_access) do |attrs,(attr,values)|
        attrs[attr] = values.is_a?(Array) ? values.last : values
        attrs
      end
    end

    # Returns a hash of the changed attributes with the old values
    def old_attributes
      (audited_changes || {}).inject({}.with_indifferent_access) do |attrs,(attr,values)|
        attrs[attr] = Array(values).first

        attrs
      end
    end

    private
    def set_version_number
      max = self.class.where(
        :auditable_id => auditable_id,
        :auditable_type => auditable_type
      ).order(:version.desc).first.try(:version) || 0
      self.version = max + 1
    end

    def set_audit_user
      self.user = Thread.current[:audited_user] if Thread.current[:audited_user]
      nil # prevent stopping callback chains
    end
  end
end
