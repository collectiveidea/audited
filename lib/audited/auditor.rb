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
      #     [self.primary_key, inheritance_column, 'lock_version', 'created_at', 'updated_at']
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

        extend Audited::Auditor::AuditedClassMethods
        include Audited::Auditor::AuditedInstanceMethods

        class_attribute :audit_associated_with,   instance_writer: false
        class_attribute :audited_options,         instance_writer: false
        class_attribute :audit_class,             instance_writer: false

        attr_accessor :version, :audit_comment

        self.audited_options = options
        normalize_audited_options

        self.audit_associated_with = audited_options[:associated_with]
        self.audit_class = audited_options[:class_name].constantize

        if audited_options[:comment_required]
          validates_presence_of :audit_comment, if: :auditing_enabled
          before_destroy :require_comment
        end

        has_many :audits, -> { order(version: :asc) }, as: :auditable, class_name: audit_class.name
        audit_class.audited_class_names << to_s

        after_create :audit_create    if audited_options[:on].include?(:create)
        before_update :audit_update   if audited_options[:on].include?(:update)
        before_destroy :audit_destroy if audited_options[:on].include?(:destroy)

        # Define and set after_audit and around_audit callbacks. This might be useful if you want
        # to notify a party after the audit has been created or if you want to access the newly-created
        # audit.
        define_callbacks :audit
        set_callback :audit, :after, :after_audit, if: lambda { respond_to?(:after_audit, true) }
        set_callback :audit, :around, :around_audit, if: lambda { respond_to?(:around_audit, true) }

        enable_auditing
      end

      def has_associated_audits(options = {})
        audit_class_name = options[:class_name] || Audited.audit_class.name
        has_many :associated_audits, as: :associated, class_name: audit_class_name
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
        return [] if audits.from_version(from_version).empty?

        loaded_audits = audits.select([:audited_changes, :version]).to_a
        targeted_audits = loaded_audits.select { |audit| audit.version >= from_version }

        targeted_audits.map do |audit|
          ancestors = loaded_audits.select { |a| a.version <= audit.version  }
          revision_with(reconstruct_attributes(ancestors).merge(version: audit.version))
        end
      end

      # Get a specific revision specified by the version number, or +:previous+
      # Returns nil for versions greater than revisions count
      def revision(version)
        if version == :previous || self.audits.last.version >= version
          revision_with audit_class.reconstruct_attributes(audits_to(version))
        end
      end

      # Find the oldest revision recorded prior to the date/time provided.
      def revision_at(date_or_time)
        audits = self.audits.up_until(date_or_time)
        revision_with audit_class.reconstruct_attributes(audits) unless audits.empty?
      end

      # List of attributes that are audited.
      def audited_attributes
        attributes.except(*non_audited_columns)
      end

      protected

      def non_audited_columns
        self.class.non_audited_columns
      end

      def audited_columns
        self.class.audited_columns
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
          audit_class.assign_revision_attributes(revision, attributes)

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
        all_changes = respond_to?(:changes_to_save) ? changes_to_save : changes
        if audited_options[:only].present?
          all_changes.slice(*audited_columns)
        else
          all_changes.except(*non_audited_columns)
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

      def auditing_enabled
        self.class.auditing_enabled
      end

      def auditing_enabled=(val)
        self.class.auditing_enabled = val
      end

      def reconstruct_attributes(audits)
        attributes = {}
        audits.each { |audit| attributes.merge!(audit.new_attributes) }
        attributes
      end
    end # InstanceMethods

    module AuditedClassMethods
      # Returns an array of columns that are audited. See non_audited_columns
      def audited_columns
        @audited_columns ||= column_names - non_audited_columns
      end

      # We have to calculate this here since column_names may not be available when `audited` is called
      def non_audited_columns
        @non_audited_columns ||= audited_options[:only].present? ?
                                 column_names - audited_options[:only] :
                                 default_ignored_attributes | audited_options[:except]
      end

      def non_audited_columns=(columns)
        @audited_columns = nil # reset cached audited columns on assignment
        @non_audited_columns = columns.map(&:to_s)
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
        audit_class.as_user(user, &block)
      end

      def auditing_enabled
        Audited.store.fetch("#{table_name}_auditing_enabled", true)
      end

      def auditing_enabled=(val)
        Audited.store["#{table_name}_auditing_enabled"] = val
      end

      protected
      def default_ignored_attributes
        [primary_key, inheritance_column] + Audited.ignored_attributes
      end

      def normalize_audited_options
        audited_options[:on] = Array.wrap(audited_options[:on])
        audited_options[:on] = [:create, :update, :destroy] if audited_options[:on].empty?
        audited_options[:only] = Array.wrap(audited_options[:only]).map(&:to_s)
        audited_options[:except] = Array.wrap(audited_options[:except]).map(&:to_s)
        audited_options[:class_name] ||= Audited.audit_class.name
      end
    end
  end
end
