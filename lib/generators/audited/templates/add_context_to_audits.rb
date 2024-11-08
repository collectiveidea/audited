# frozen_string_literal: true

<%- table_name = options[:audited_table_name].underscore.pluralize -%>
class <%= migration_class_name %> < <%= migration_parent %>
  def self.up
    add_column :<%= table_name %>, :context, :jsonb
  end

  def self.down
    remove_column :<%= table_name %>, :context
  end
end
