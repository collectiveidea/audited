module ActsAsAudited
  # Specify this act if you want changes to your model to be saved in an
  # audit table.  This assumes there is an audits table ready.
  #
  #   class User < ActiveRecord::Base
  #     acts_as_audited
  #   end
  #
  # To store an audit comment set model.audit_comment to your comment before
  # a create, update or destroy operation.
  #
  # See <tt>ActsAsAudited::Auditor::ClassMethods#acts_as_audited</tt>
  # for configuration options
  module Auditor #:nodoc:
    CALLBACKS = [:audit_create, :audit_update, :audit_destroy]

    # @private
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # == Configuration options
      #
      #
      # * +only+ - Only audit the given attributes
      # * +except+ - Excludes fields from being saved in the audit log.
      #   By default, acts_as_audited will audit all but these fields:
      #
      #     [self.primary_key, inheritance_column, 'lock_version', 'created_at', 'updated_at']
      #   You can add to those by passing one or an array of fields to skip.
      #
      #     class User < ActiveRecord::Base
      #       acts_as_audited :except => :password
      #     end
      # * +protect+ - If your model uses +attr_protected+, set this to false to prevent Rails from
      #   raising an error.  If you declare +attr_accessibe+ before calling +acts_as_audited+, it
      #   will automatically default to false.  You only need to explicitly set this if you are
      #   calling +attr_accessible+ after.
      #
      # * +require_comment+ - Ensures that audit_comment is supplied before
      #   any create, update or destroy operation.
      #
      #     class User < ActiveRecord::Base
      #       acts_as_audited :protect => false
      #       attr_accessible :name
      #     end
      #
      def acts_as_audited(options = {})
        # don't allow multiple calls
        return if self.included_modules.include?(ActsAsAudited::Auditor::InstanceMethods)

        options = {:protect => accessible_attributes.empty?}.merge(options)

        #class_inheritable_reader :non_audited_columns
        #class_inheritable_reader :auditing_enabled
        #class_inheritable_reader :audit_associated_with

        class_attribute :non_audited_columns, {:instance_writer => false}
        class_attribute :auditing_enabled, {:instance_writer => false}
        class_attribute :audit_associated_with, {:instance_writer => false}

        if options[:only]
          except = self.column_names - options[:only].flatten.map(&:to_s)
        else
          except = [self.primary_key, inheritance_column, 'lock_version',
            'created_at', 'updated_at', 'created_on', 'updated_on']
          except |= Array(options[:except]).collect(&:to_s) if options[:except]
        end
        #write_inheritable_attribute :non_audited_columns, except
        #write_inheritable_attribute :audit_associated_with, options[:associated_with]
        self.non_audited_columns = except
        self.audit_associated_with = options[:associated_with]

        if options[:comment_required]
          validates_presence_of :audit_comment, :if => :auditing_enabled
          before_destroy :require_comment
        end

        attr_accessor :audit_comment
        unless accessible_attributes.empty? || options[:protect]
          attr_accessible :audit_comment
        end

        has_many :audits, :as => :auditable
        attr_protected :audit_ids if options[:protect]
        Audit.audited_class_names << self.to_s

        after_create  :audit_create if !options[:on] || (options[:on] && options[:on].include?(:create))
        before_update :audit_update if !options[:on] || (options[:on] && options[:on].include?(:update))
        before_destroy :audit_destroy if !options[:on] || (options[:on] && options[:on].include?(:destroy))

        attr_accessor :version

        extend ActsAsAudited::Auditor::SingletonMethods
        include ActsAsAudited::Auditor::InstanceMethods

        #write_inheritable_attribute :auditing_enabled, true
        self.auditing_enabled = true
      end

      def has_associated_audits
        has_many :associated_audits, :as => :associated, :class_name => "Audit"
      end

    end

    module InstanceMethods

      # Temporarily turns off auditing while saving.
      def save_without_auditing
        without_auditing { save }
      end

      # Executes the block with the auditing callbacks disabled.
      #
      #   @foo.without_auditing do
      #     @foo.save
      #   end
      #
      def without_auditing(&block)
        self.class.without_auditing(&block)
      end

      # Gets an array of the revisions available
      #
      #   user.revisions.each do |revision|
      #     user.name
      #     user.version
      #   end
      #
      def revisions(from_version = 1)
        audits = self.audits.where(['version >= ?', from_version])
        return [] if audits.empty?
        revision = self.audits.find_by_version(from_version).revision
        Audit.reconstruct_attributes(audits) {|attrs| revision.revision_with(attrs) }
      end

      # Get a specific revision specified by the version number, or +:previous+
      def revision(version)
        revision_with Audit.reconstruct_attributes(audits_to(version))
      end

      # Find the oldest revision recorded prior to the date/time provided.
      def revision_at(date_or_time)
        audits = self.audits.where("created_at <= ?", date_or_time)
        revision_with Audit.reconstruct_attributes(audits) unless audits.empty?
      end

      # List of attributes that are audited.
      def audited_attributes
        attributes.except(*non_audited_columns)
      end

      protected

      def revision_with(attributes)
        self.dup.tap do |revision|
          revision.send :instance_variable_set, '@attributes', self.attributes_before_type_cast
          revision.send :instance_variable_set, '@new_record', self.destroyed?
          revision.send :instance_variable_set, '@persisted', !self.destroyed?
          revision.send :instance_variable_set, '@readonly', false
          revision.send :instance_variable_set, '@destroyed', false
          revision.send :instance_variable_set, '@marked_for_destruction', false
          Audit.assign_revision_attributes(revision, attributes)

          # Remove any association proxies so that they will be recreated
          # and reference the correct object for this revision. The only way
          # to determine if an instance variable is a proxy object is to
          # see if it responds to certain methods, as it forwards almost
          # everything to its target.
          for ivar in revision.instance_variables
            proxy = revision.instance_variable_get ivar
            if !proxy.nil? and proxy.respond_to? :proxy_respond_to?
              revision.instance_variable_set ivar, nil
            end
          end
        end
      end

      private

      def audited_changes
        changed_attributes.except(*non_audited_columns).inject({}) do |changes,(attr, old_value)|
          changes[attr] = [old_value, self[attr]]
          changes
        end
      end

      def audits_to(version = nil)
        if version == :previous
          version = if self.version
            self.version - 1
          else
            previous = audits.descending.offset(1).first
            previous ? previous.version : 1
          end
        end
        audits.where(['version <= ?', version])
      end

      def audit_create
        write_audit(:action => 'create', :audited_changes => audited_attributes,
          :comment => audit_comment)
      end

      def audit_update
        unless (changes = audited_changes).empty?
          write_audit(:action => 'update', :audited_changes => changes,
            :comment => audit_comment)
        end
      end

      def audit_destroy
        write_audit(:action => 'destroy', :audited_changes => audited_attributes,
          :comment => audit_comment)
      end

      def write_audit(attrs)
        attrs[:associated] = self.send(audit_associated_with) unless audit_associated_with.nil?
        self.audit_comment = nil
        self.audits.create attrs if auditing_enabled
      end

      def require_comment
        if auditing_enabled && audit_comment.blank?
          errors.add(:audit_comment, "Comment required before destruction")
          return false
        end
      end

      CALLBACKS.each do |attr_name|
        alias_method "#{attr_name}_callback".to_sym, attr_name
      end

      def empty_callback #:nodoc:
      end

    end # InstanceMethods

    module SingletonMethods
      # Returns an array of columns that are audited.  See non_audited_columns
      def audited_columns
        self.columns.select { |c| !non_audited_columns.include?(c.name) }
      end

      # Executes the block with auditing disabled.
      #
      #   Foo.without_auditing do
      #     @foo.save
      #   end
      #
      def without_auditing(&block)
        auditing_was_enabled = auditing_enabled
        disable_auditing
        block.call.tap { enable_auditing if auditing_was_enabled }
      end

      # Disable auditing.
      def disable_auditing
        #write_inheritable_attribute :auditing_enabled, false
        self.auditing_enabled = false
      end

      # Enable auditing.
      def enable_auditing
        #write_inheritable_attribute :auditing_enabled, true
        self.auditing_enabled = true
      end

      # All audit operations during the block are recorded as being
      # made by +user+. This is not model specific, the method is a
      # convenience wrapper around
      # @see Audit#as_user.
      def audit_as( user, &block )
        Audit.as_user( user, &block )
      end

    end
  end
end
