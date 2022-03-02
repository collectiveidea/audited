# frozen_string_literal: true

class <%= :audit_trails %> < <%= migration_parent %>
  def self.up
    if index_exists?(:audit_trails, [:auditable_type, :auditable_id], name: index_name)
      remove_index :audit_trails, name: index_name
      add_index :audit_trails, [:auditable_type, :auditable_id, :version], name: index_name
    end
  end

  def self.down
    if index_exists?(:audit_trails, [:auditable_type, :auditable_id, :version], name: index_name)
      remove_index :audit_trails, name: index_name
      add_index :audit_trails, [:auditable_type, :auditable_id], name: index_name
    end
  end

  private

  def index_name
    'auditable_index'
  end
end
