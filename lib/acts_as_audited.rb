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
      CALLBACKS = [:clear_changed_attributes, :audit_create, :audit_update, :audit_destroy]

      def self.included(base) # :nodoc:
        base.extend ClassMethods
      end

      module ClassMethods
        # == Configuration options
        #
        # * <tt>except</tt> - Excludes fields from being saved in the audit log.
        #   By default, acts_as_audited will audit all but these fields: 
        # 
        #     [self.primary_key, inheritance_column, 'lock_version', 'created_at', 'updated_at']
        #
        #   You can add to those by passing one or an array of fields to skip.
        #
        #     class User < ActiveRecord::Base
        #       acts_as_audited :except => :password
        #     end
        # 
        def acts_as_audited(options = {})
          # don't allow multiple calls
          return if self.included_modules.include?(CollectiveIdea::Acts::Audited::InstanceMethods)

          include CollectiveIdea::Acts::Audited::InstanceMethods
          
          class_eval do
            extend CollectiveIdea::Acts::Audited::SingletonMethods

            cattr_accessor :non_audited_columns, :auditing_enabled

            self.non_audited_columns = [self.primary_key, inheritance_column, 'lock_version', 'created_at', 'updated_at']
            self.non_audited_columns |= options[:except].is_a?(Array) ?
              options[:except].collect{|column| column.to_s} : [options[:except].to_s] if options[:except]

            has_many :audits, :as => :auditable
            attr_protected :audit_ids
            Audit.audited_classes << self
            
            after_create :audit_create
            after_update :audit_update
            after_destroy :audit_destroy
            after_save :clear_changed_attributes

            self.auditing_enabled = true
          end
        end
      end
    
      module InstanceMethods
        # Temporarily turns off auditing while saving.
        def save_without_auditing
          without_auditing do
            save
          end
        end
      
        # Returns an array of attribute keys that are audited.  See non_audited_columns
        def audited_attributes
          self.attributes.keys.select { |k| !self.class.non_audited_columns.include?(k) }
        end
        
        # If called with no parameters, gets whether the current model has changed.
        # If called with a single parameter, gets whether the parameter has changed.
        def changed?(attr_name = nil)
          @changed_attributes ||= {}
            attr_name.nil? ? !@changed_attributes.empty? : @changed_attributes.include?(attr_name.to_s)
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

        private
          # Creates a new record in the audits table if applicable
          def audit_create
            write_audit(:create)
          end
  
          def audit_update
            write_audit(:update) if changed?
          end
  
          def audit_destroy
            write_audit(:destroy)
          end
        
          def write_audit(action = :update, user = nil)
            self.audits.create :changes => @changed_attributes, :action => action.to_s, :user => user
          end

          # clears current changed attributes.  Called after save.
          def clear_changed_attributes
            @changed_attributes = {}
          end
          
          # overload write_attribute to save changes to audited attributes
          def write_attribute(attr_name, attr_value)
            attr_name = attr_name.to_s
            if audited_attributes.include?(attr_name)
              @changed_attributes ||= {}
              # get original value
              old_value = @changed_attributes[attr_name] ?
                @changed_attributes[attr_name].first : self[attr_name]
              super(attr_name, attr_value)
              new_value = self[attr_name]
              
              @changed_attributes[attr_name] = [old_value, new_value] if new_value != old_value
            else
              super(attr_name, attr_value)
            end
          end

          CALLBACKS.each do |attr_name| 
            alias_method "orig_#{attr_name}".to_sym, attr_name
          end
          
          def empty_callback() end #:nodoc:

      end # InstanceMethods
      
      module SingletonMethods
        # Returns an array of columns that are audited.  See non_audited_columns
        def audited_columns
          self.columns.select { |c| !non_audited_columns.include?(c.name) }
        end

        # Executes the block with the auditing callbacks disabled.
        #
        #   Foo.without_auditing do
        #     @foo.save
        #   end
        #
        def without_auditing(&block)
          auditing_was_enabled = auditing_enabled
          disable_auditing
          result = block.call
          enable_auditing if auditing_was_enabled
          result
        end
        
        def disable_auditing
          class_eval do 
            CALLBACKS.each do |attr_name| 
              alias_method attr_name, :empty_callback
            end
          end
          self.auditing_enabled = false
        end
        
        def enable_auditing
          class_eval do 
            CALLBACKS.each do |attr_name|
              alias_method attr_name, "orig_#{attr_name}".to_sym
            end
          end
          self.auditing_enabled = true
        end

      end
    end
  end
end
