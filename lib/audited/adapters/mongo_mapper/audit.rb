require 'set'
require 'audited/audit'

module Audited
  module Adapters
    module MongoMapper
      # Audit saves the changes to ActiveRecord models.  It has the following attributes:
      #
      # * <tt>auditable</tt>: the ActiveRecord model that was changed
      # * <tt>user</tt>: the user that performed the change; a string or an ActiveRecord model
      # * <tt>action</tt>: one of create, update, or delete
      # * <tt>audited_changes</tt>: a serialized hash of all the changes
      # * <tt>comment</tt>: a comment set with the audit
      # * <tt>created_at</tt>: Time that the change was performed
      #
      class Audit
        include ::MongoMapper::Document
        include ActiveModel::Observing

        key :auditable_id, ObjectId
        key :auditable_type, String
        key :associated_id, ObjectId
        key :associated_type, String
        key :user_id, ObjectId
        key :user_type, String
        key :username, String
        key :action, String
        key :audited_changes, AuditedChanges
        key :version, Integer, :default => 0
        key :comment, String
        key :remote_address, String
        key :created_at, Time

        include Audited::Audit

        before_create :set_created_at

        def self.acending;   sort(:version.asc); end
        def self.ascending;  sort(:version.asc); end
        def self.descending; sort(:version.desc); end
        def self.creates;    where(:action => 'create'); end
        def self.updates;    where(:action => 'update'); end
        def self.destroys;   where(:action => 'destroy'); end

        def self.up_until(date_or_time); where(:created_at.lte => date_or_time); end
        def self.from_version(version);  where(:version.gte => version); end
        def self.to_version(version);    where(:version.lte => version); end

        class << self

          # @private
          def sanitize_for_time_with_zone(value)
            case value
            when Hash
              value.inject({}){|h,(k,v)| h[k] = sanitize_for_time_with_zone(v); h }
            when Array
              value.map{|v| sanitize_for_time_with_zone(v) }
            when ActiveSupport::TimeWithZone
              value.utc
            else
              value
            end
          end
        end

        def audited_changes=(value)
          self[:audited_changes] = self.class.sanitize_for_time_with_zone(value)
        end

        # Allows user to be set to either a string or an ActiveRecord object
        # @private
        def user_as_string=(user)
          # reset both either way
          self.user_as_model = self.username = nil
          user.is_a?(::MongoMapper::Document) ?
            self.user_as_model = user :
            self.username = user
        end
        alias_method :user_as_model=, :user=
        alias_method :user=, :user_as_string=

        # @private
        def user_as_string
          self.user_as_model || self.username
        end
        alias_method :user_as_model, :user
        alias_method :user, :user_as_string

        # Return all audits older than the current one.
        def ancestors
          self.class.where(:auditable_id => auditable_id, :auditable_type => auditable_type, :version.lte => version)
        end

        def set_created_at
          self[:created_at] = Time.now.utc if !persisted? && !created_at?
        end
      end
    end
  end
end
