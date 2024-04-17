class <%= migration_class_name %> < <%= migration_parent %>
  def self.up
    create_table :audit_associations, :force => true do |t|
      t.column :audit_id, :integer
      t.column :associated_id, :integer
      t.column :associated_type, :string
    end

    execute <<-SQL
      INSERT INTO audit_associations (audit_id, associated_id, associated_type)
        SELECT id, associated_id, associated_type
        FROM audits
    SQL

    add_index :audit_associations, :audit_id, :name => 'index_audit_associations_on_audit_id'
    add_index :audit_associations, [:associated_type, :associated_id], :name => 'index_audit_associations_on_associated'

    remove_index :audits, name: 'associated_index'
    remove_column :audits, :associated_id
    remove_column :audits, :associated_type
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
