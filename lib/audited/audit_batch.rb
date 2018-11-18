require 'pry'
require 'activerecord-import'

module Audited
  class AuditBatch

    def initialize(relation, updates, comment = '')
      @relation = relation
      @updates = updates
      @audited_updates = @updates.except(*calculate_non_audited_columns)
      @comment = comment
    end

    def create
      if @relation.update_all(@updates)
        serialized_updates = Audited::YAMLIfTextColumnType.load(@audited_updates)
        audits = old_attributes.map do |value|
          {
            auditable_id: value['id'],
            auditable_type: @relation.name,
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
        query = @relation.select(:id, *@audited_updates.keys).to_sql
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

    def default_ignored_attributes
      [@relation.primary_key, @relation.inheritance_column] | Audited.ignored_attributes
    end

    protected

    def normalize_audited_options
      options = @relation.audited_options
      options[:on] = Array.wrap(options[:on])
      options[:on] = [:create, :update, :destroy] if options[:on].empty?
      options[:only] = Array.wrap(options[:only]).map(&:to_s)
      options[:except] = Array.wrap(options[:except]).map(&:to_s)
      max_audits = options[:max_audits] || Audited.max_audits
      options[:max_audits] = Integer(max_audits).abs if max_audits
    end

    def calculate_non_audited_columns
      if @relation.audited_options[:only].present?
        (column_names | default_ignored_attributes) - @relation.audited_options[:only]
      elsif @relation.audited_options[:except].present?
        default_ignored_attributes | @relation.audited_options[:except]
      else
        default_ignored_attributes
      end
    end

  end
end
