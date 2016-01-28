require 'set'

module Audited
  # Audit saves the changes to ActiveRecord models.  It has the following attributes:
  #
  # * <tt>auditable</tt>: the ActiveRecord model that was changed
  # * <tt>user</tt>: the user that performed the change; a string or an ActiveRecord model
  # * <tt>action</tt>: one of create, update, or delete
  # * <tt>audited_changes</tt>: a serialized hash of all the changes
  # * <tt>comment</tt>: a comment set with the audit
  # * <tt>version</tt>: the version of the model
  # * <tt>request_uuid</tt>: a uuid based that allows audits from the same controller request
  # * <tt>created_at</tt>: Time that the change was performed
  #
  class Audit < ::ActiveRecord::Base
    include ActiveModel::Observing

    belongs_to :auditable,  polymorphic: true
    belongs_to :user,       polymorphic: true
    belongs_to :associated, polymorphic: true

    before_create :set_version_number, :set_audit_user, :set_request_uuid

    cattr_accessor :audited_class_names
    self.audited_class_names = Set.new

    serialize :audited_changes

    scope :ascending,     ->{ reorder(version: :asc) }
    scope :descending,    ->{ reorder(version: :desc)}
    scope :creates,       ->{ where(action: 'create')}
    scope :updates,       ->{ where(action: 'update')}
    scope :destroys,      ->{ where(action: 'destroy')}

    scope :up_until,      ->(date_or_time){where("created_at <= ?", date_or_time) }
    scope :from_version,  ->(version){where(['version >= ?', version]) }
    scope :to_version,    ->(version){where(['version <= ?', version]) }
    scope :auditable_finder, ->(auditable_id, auditable_type){where(auditable_id: auditable_id, auditable_type: auditable_type)}
    # Return all audits older than the current one.
    def ancestors
      self.class.ascending.auditable_finder(auditable_id, auditable_type).to_version(version)
    end

    # Return an instance of what the object looked like at this revision. If
    # the object has been destroyed, this will be a new record.
    def revision
      clazz = auditable_type.constantize
      (clazz.find_by_id(auditable_id) || clazz.new).tap do |m|
        self.class.assign_revision_attributes(m, self.class.reconstruct_attributes(ancestors).merge(version: version))
      end
    end

    # Returns a hash of the changed attributes with the new values
    def new_attributes
      (audited_changes || {}).inject({}.with_indifferent_access) do |attrs, (attr, values)|
        attrs[attr] = values.is_a?(Array) ? values.last : values
        attrs
      end
    end

    # Returns a hash of the changed attributes with the old values
    def old_attributes
      (audited_changes || {}).inject({}.with_indifferent_access) do |attrs, (attr, values)|
        attrs[attr] = Array(values).first

        attrs
      end
    end

    # Allows user to be set to either a string or an ActiveRecord object
    # @private
    def user_as_string=(user)
      # reset both either way
      self.user_as_model = self.username = nil
      user.is_a?(::ActiveRecord::Base) ?
        self.user_as_model = user :
        self.username = user
    end
    alias_method :user_as_model=, :user=
    alias_method :user=, :user_as_string=

    # @private
    def user_as_string
      user_as_model || username
    end
    alias_method :user_as_model, :user
    alias_method :user, :user_as_string

    # Returns the list of classes that are being audited
    def self.audited_classes
      audited_class_names.map(&:constantize)
    end

    # All audits made during the block called will be recorded as made
    # by +user+. This method is hopefully threadsafe, making it ideal
    # for background operations that require audit information.
    def self.as_user(user, &block)
      Thread.current[:audited_user] = user
      yield
    ensure
      Thread.current[:audited_user] = nil
    end

    # @private
    def self.reconstruct_attributes(audits)
      attributes = {}
      result = audits.collect do |audit|
        attributes.merge!(audit.new_attributes).merge!(version: audit.version)
        yield attributes if block_given?
      end
      block_given? ? result : attributes
    end

    # @private
    def self.assign_revision_attributes(record, attributes)
      attributes.each do |attr, val|
        record = record.dup if record.frozen?

        if record.respond_to?("#{attr}=")
          record.attributes.key?(attr.to_s) ?
            record[attr] = val :
            record.send("#{attr}=", val)
        end
      end
      record
    end

    private

    def set_version_number
      max = self.class.auditable_finder(auditable_id, auditable_type).descending.first.try(:version) || 0
      self.version = max + 1
    end

    def set_audit_user
      self.user = Thread.current[:audited_user] if Thread.current[:audited_user]
      nil # prevent stopping callback chains
    end

    def set_request_uuid
      self.request_uuid ||= SecureRandom.uuid
    end
  end

end
