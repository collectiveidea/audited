# frozen_string_literal: true

<%- table_name = options[:audited_table_name].underscore.pluralize -%>
class <%= migration_class_name %> < <%= migration_parent %>
  def self.up
    add_column :<%= table_name %>, :audited_context, :<%= options[:audited_context_column_type] %>
  end

  def self.down
    remove_column :<%= table_name %>, :audited_context
  end
end
