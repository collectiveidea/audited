<%- table_name = options[:audited_table_name].underscore.pluralize -%>
class <%= table_name.singularize.classify %> < Audited::Audit
  self.table_name = "<%= table_name %>"
end
