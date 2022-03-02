# frozen_string_literal: true

class <%= migration_class_name %> < <%= migration_parent %>
  def self.up
    if index_exists? :audit_trails, [:association_id, :association_type], :name => 'association_index'
      remove_index :audit_trails, :name => 'association_index'
    end

    rename_column :audit_trails, :association_id, :associated_id
    rename_column :audit_trails, :association_type, :associated_type

    add_index :audit_trails, [:associated_id, :associated_type], :name => 'associated_index'
  end

  def self.down
    if index_exists? :audit_trails, [:associated_id, :associated_type], :name => 'associated_index'
      remove_index :audit_trails, :name => 'associated_index'
    end

    rename_column :audit_trails, :associated_type, :association_type
    rename_column :audit_trails, :associated_id, :association_id

    add_index :audit_trails, [:association_id, :association_type], :name => 'association_index'
  end
end
