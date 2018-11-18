require 'pry'
require 'activerecord-import'

module Audited
  class AuditBatch

    def initialize(resource, updates, comment = '')
      @resource = resource
      @updates =  updates
      @comment =  comment
    end

    def create
      if @resource.update_all(@updates)
        serialized_updates = Audited::YAMLIfTextColumnType.load(audited_updates)
        audits = old_attributes.map do |value|
          {
            auditable_id: value['id'],
            auditable_type: @resource.name,
            audited_changes: serialized_updates,
            comment: @comment,
          }
        end

        Audited.audit_class.import(audits)
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
      @old_attributes ||= begin
        query = @resource.select(:id, *audited_updates.keys).to_sql
        result = ActiveRecord::Base.connection.exec_query(query)
        result.to_hash
      end
    end

    private

    # def before_create
    #   set_version_number
    #   set_audit_user
    #   set_request_uuid
    #   set_remote_address
    # end

    # def set_version_number
    #   max = self.class.auditable_finder(auditable_id, auditable_type).maximum(:version) || 0
    #   self.version = max + 1
    # end

    # def set_audit_user
    #   self.user ||= ::Audited.store[:audited_user] # from .as_user
    #   self.user ||= ::Audited.store[:current_user].try!(:call) # from Sweeper
    #   nil # prevent stopping callback chains
    # end

    # def set_request_uuid
    #   self.request_uuid ||= ::Audited.store[:current_request_uuid]
    #   self.request_uuid ||= SecureRandom.uuid
    # end

    # def set_remote_address
    #   self.remote_address ||= ::Audited.store[:current_remote_address]
    # end

    def audited_updates
      @updates.except(*calculate_non_audited_columns)
    end

    def default_ignored_attributes
      [@resource.primary_key, @resource.inheritance_column] | Audited.ignored_attributes
    end

    protected

    def calculate_non_audited_columns
      if @resource.audited_options[:only].present?
        (@resource.column_names | default_ignored_attributes) - @resource.audited_options[:only]
      elsif @resource.audited_options[:except].present?
        default_ignored_attributes | @resource.audited_options[:except]
      else
        default_ignored_attributes
      end
    end

  end
end
