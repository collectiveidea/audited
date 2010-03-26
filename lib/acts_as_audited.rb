# Copyright (c) 2006 Brandon Keepers
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module CollectiveIdea #:nodoc:
  module Acts #:nodoc:
    # Specify this act if you want changes to your model to be saved in an
    # audit table.  This assumes there is an audits table ready.
    #
    #   class User < ActiveRecord::Base
    #     acts_as_audited
    #   end
    #
    # See <tt>CollectiveIdea::Acts::Audited::ClassMethods#acts_as_audited</tt>
    # for configuration options
    module Audited #:nodoc:
      CALLBACKS = [:audit_create, :audit_update, :audit_destroy]

      def self.included(base) # :nodoc:
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
        #     class User < ActiveRecord::Base
        #       acts_as_audited :protect => false
        #       attr_accessible :name
        #     end
        #
        def acts_as_audited(options = {})
          # don't allow multiple calls
          return if self.included_modules.include?(CollectiveIdea::Acts::Audited::InstanceMethods)

          options = {:protect => accessible_attributes.nil?}.merge(options)

          class_inheritable_reader :non_audited_columns
          class_inheritable_reader :auditing_enabled

          if options[:only]
            except = self.column_names - options[:only].flatten.map(&:to_s)
          else
            except = [self.primary_key, inheritance_column, 'lock_version', 'created_at', 'updated_at']
            except |= Array(options[:except]).collect(&:to_s) if options[:except]
          end
          write_inheritable_attribute :non_audited_columns, except

          has_many :audits, :as => :auditable, :order => "#{Audit.quoted_table_name}.version"
          attr_protected :audit_ids if options[:protect]
          Audit.audited_class_names << self.to_s

          after_create  :audit_create
          before_update :audit_update
          after_destroy :audit_destroy

          attr_accessor :version

          extend CollectiveIdea::Acts::Audited::SingletonMethods
          include CollectiveIdea::Acts::Audited::InstanceMethods

          write_inheritable_attribute :auditing_enabled, true
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
          audits = self.audits.find(:all, :conditions => ['version >= ?', from_version])
          return [] if audits.empty?
          revision = self.audits.find_by_version(from_version).revision
          Audit.reconstruct_attributes(audits) {|attrs| revision.revision_with(attrs) }
        end

        # Get a specific revision specified by the version number, or +:previous+
        def revision(version)
          revision_with Audit.reconstruct_attributes(audits_to(version))
        end

        def revision_at(date_or_time)
          audits = self.audits.find(:all, :conditions => ["created_at <= ?", date_or_time])
          revision_with Audit.reconstruct_attributes(audits) unless audits.empty?
        end

        def audited_attributes
          attributes.except(*non_audited_columns)
        end

      protected

        def revision_with(attributes)
          returning self.dup do |revision|
            revision.send :instance_variable_set, '@attributes', self.attributes_before_type_cast
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
              previous = audits.find(:first, :offset => 1,
                :order => "#{Audit.quoted_table_name}.version DESC")
              previous ? previous.version : 1
            end
          end
          audits.find(:all, :conditions => ['version <= ?', version])
        end

        def audit_create
          write_audit(:action => 'create', :changes => audited_attributes)
        end

        def audit_update
          unless (changes = audited_changes).empty?
            write_audit(:action => 'update', :changes => changes)
          end
        end

        def audit_destroy
          write_audit(:action => 'destroy', :changes => audited_attributes)
        end

        def write_audit(attrs)
          self.audits.create attrs if auditing_enabled
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
          returning(block.call) { enable_auditing if auditing_was_enabled }
        end

        def disable_auditing
          write_inheritable_attribute :auditing_enabled, false
        end

        def enable_auditing
          write_inheritable_attribute :auditing_enabled, true
        end

        # All audit operations during the block are recorded as being
        # made by +user+. This is not model specific, the method is a
        # convenience wrapper around #Audit.as_user.
        def audit_as( user, &block )
          Audit.as_user( user, &block )
        end

      end
    end
  end
end
