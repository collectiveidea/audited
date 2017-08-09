module Audited
  # Specify this act if you want changes to your model to be saved in an
  # audit table.  This assumes there is an audits table ready.
  #
  #   class User < ActiveRecord::Base
  #     audited
  #   end
  #
  # To store an audit comment set model.audit_comment to your comment before
  # a create, update or destroy operation.
  #
  # See <tt>Audited::Auditor::ClassMethods#audited</tt>
  # for configuration options
  module Auditor #:nodoc:
    extend ActiveSupport::Concern

    CALLBACKS = [:audit_create, :audit_update, :audit_destroy]

    module ClassMethods
      # == Configuration options
      #
      #
      # * +only+ - Only audit the given attributes
      # * +except+ - Excludes fields from being saved in the audit log.
      #   By default, Audited will audit all but these fields:
      #
      #     [self.primary_key, 'lock_version', 'created_at', 'updated_at']
      #   You can add to those by passing one or an array of fields to skip.
      #
      #     class User < ActiveRecord::Base
      #       audited except: :password
      #     end
      #
      # * +require_comment+ - Ensures that audit_comment is supplied before
      #   any create, update or destroy operation.
      #
      def audited(options = {})
        # don't allow multiple calls
        return if included_modules.include?(Audited::Auditor::AuditedInstanceMethods)

        class_attribute :audit_associated_with,   instance_writer: false
        class_attribute :audited_options,       instance_writer: false

        self.audited_options = options
        self.audit_associated_with = options[:associated_with]

        if options[:comment_required]
          validates_presence_of :audit_comment, if: :auditing_enabled
          before_destroy :require_comment
        end

        attr_accessor :audit_comment

        has_many :audits, -> { order(version: :asc) }, as: :auditable, class_name: Audited.audit_class.name
        Audited.audit_class.audited_class_names << to_s

        on = Array(options[:on])
        after_create :audit_create    if on.empty? || on.include?(:create)
        before_update :audit_update   if on.empty? || on.include?(:update)
        before_destroy :audit_destroy if on.empty? || on.include?(:destroy)

        # Define and set after_audit and around_audit callbacks. This might be useful if you want
        # to notify a party after the audit has been created or if you want to access the newly-created
        # audit.
        define_callbacks :audit
        set_callback :audit, :after, :after_audit, if: lambda { respond_to?(:after_audit, true) }
        set_callback :audit, :around, :around_audit, if: lambda { respond_to?(:around_audit, true) }

        attr_accessor :version

        extend Audited::Auditor::AuditedClassMethods
        include Audited::Auditor::AuditedInstanceMethods

        self.auditing_enabled = true
      end

      def has_associated_audits
        has_many :associated_audits, as: :associated, class_name: Audited.audit_class.name
      end

      def default_ignored_attributes
        [primary_key]
      end
    end

    module AuditedInstanceMethods
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
        audits = self.audits.from_version(from_version)
        return [] if audits.empty?
        revisions = []
        audits.each do |audit|
          revisions << audit.revision
        end
        revisions
      end

      # Get a specific revision specified by the version number, or +:previous+
      def revision(version)
        revision_with Audited.audit_class.reconstruct_attributes(audits_to(version))
      end

      # Find the oldest revision recorded prior to the date/time provided.
      def revision_at(date_or_time)
        audits = self.audits.up_until(date_or_time)
        revision_with Audited.audit_class.reconstruct_attributes(audits) unless audits.empty?
      end

      # List of attributes that are audited.
      def audited_attributes
        attributes.except(*non_audited_columns.map(&:to_s))
      end

      def non_audited_columns
        self.class.non_audited_columns
      end

      protected

      def non_audited_columns
        self.class.non_audited_columns
      end

      def revision_with(attributes)
        dup.tap do |revision|
          revision.id = id
          revision.send :instance_variable_set, '@attributes', self.attributes if rails_below?('4.2.0')
          revision.send :instance_variable_set, '@new_record', destroyed?
          revision.send :instance_variable_set, '@persisted', !destroyed?
          revision.send :instance_variable_set, '@readonly', false
          revision.send :instance_variable_set, '@destroyed', false
          revision.send :instance_variable_set, '@_destroyed', false
          revision.send :instance_variable_set, '@marked_for_destruction', false
          Audited.audit_class.assign_revision_attributes(revision, attributes)

          # Remove any association proxies so that they will be recreated
          # and reference the correct object for this revision. The only way
          # to determine if an instance variable is a proxy object is to
          # see if it responds to certain methods, as it forwards almost
          # everything to its target.
          revision.instance_variables.each do |ivar|
            proxy = revision.instance_variable_get ivar
            if !proxy.nil? && proxy.respond_to?(:proxy_respond_to?)
              revision.instance_variable_set ivar, nil
            end
          end
        end
      end

      def rails_below?(rails_version)
        Gem::Version.new(Rails::VERSION::STRING) < Gem::Version.new(rails_version)
      end

      private

      def audited_changes
        collection =
          if audited_options[:only]
            audited_columns = self.class.audited_columns.map(&:name)
            changed_attributes.slice(*audited_columns)
          else
            changed_attributes.except(*non_audited_columns)
          end

        collection.inject({}) do |changes, (attr, old_value)|
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
        audits.to_version(version)
      end

      def audit_create
        write_audit(action: 'create', audited_changes: audited_attributes,
                    comment: audit_comment)
      end

      def audit_update
        unless (changes = audited_changes).empty? && audit_comment.blank?
          write_audit(action: 'update', audited_changes: changes,
                      comment: audit_comment)
        end
      end

      def audit_destroy
        write_audit(action: 'destroy', audited_changes: audited_attributes,
                    comment: audit_comment) unless new_record?
      end

      def write_audit(attrs)
        attrs[:associated] = send(audit_associated_with) unless audit_associated_with.nil?
        self.audit_comment = nil
        run_callbacks(:audit)  { audits.create(attrs) } if auditing_enabled
      end

      def require_comment
        if auditing_enabled && audit_comment.blank?
          errors.add(:audit_comment, "Comment required before destruction")
          return false if Rails.version.start_with?('4.')
          throw :abort
        end
      end

      CALLBACKS.each do |attr_name|
        alias_method "#{attr_name}_callback".to_sym, attr_name
      end

      def empty_callback #:nodoc:
      end

      def auditing_enabled
        self.class.auditing_enabled
      end

      def auditing_enabled=(val)
        self.class.auditing_enabled = val
      end
    end # InstanceMethods

    module AuditedClassMethods
      # Returns an array of columns that are audited. See non_audited_columns
      def audited_columns
        columns.reject { |c| non_audited_columns.map(&:to_s).include?(c.name) }
      end

      def non_audited_columns
        @non_audited_columns ||= begin
          options = audited_options
          if options[:only]
            except = column_names - Array.wrap(options[:only]).flatten.map(&:to_s)
          else
            except = default_ignored_attributes + Audited.ignored_attributes
            except |= Array(options[:except]).collect(&:to_s) if options[:except]
          end
          except
        end
      end

      def non_audited_columns=(columns)
        @non_audited_columns = columns
      end

      # Executes the block with auditing disabled.
      #
      #   Foo.without_auditing do
      #     @foo.save
      #   end
      #
      def without_auditing
        auditing_was_enabled = auditing_enabled
        disable_auditing
        yield
      ensure
        enable_auditing if auditing_was_enabled
      end

      def disable_auditing
        self.auditing_enabled = false
      end

      def enable_auditing
        self.auditing_enabled = true
      end

      # All audit operations during the block are recorded as being
      # made by +user+. This is not model specific, the method is a
      # convenience wrapper around
      # @see Audit#as_user.
      def audit_as(user, &block)
        Audited.audit_class.as_user(user, &block)
      end

      def auditing_enabled
        Audited.store.fetch("#{table_name}_auditing_enabled", true)
      end

      def auditing_enabled=(val)
        Audited.store["#{table_name}_auditing_enabled"] = val
      end
    end
  end
end
