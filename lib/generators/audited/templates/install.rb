class <%= migration_class_name %> < <%= migration_parent %>
  def change
    create_table :audits do |t|
      t.references :auditable, polymorphic: true, index: false

      t.references :associated, polymorphic: true,
                                index: { name: 'associated_index' }

      t.references :user, type: :<%= options[:audited_user_id_column_type] %>,
                          polymorphic: true, index: { name: 'user_index' }

      t.string :username
      t.string :action
      t.<%= options[:audited_changes_column_type] %> :audited_changes
      t.integer :version, default: 0
      t.string :comment
      t.string :remote_address
      t.string :request_uuid
      t.datetime :created_at

      t.index [:auditable_type, :auditable_id, :version], name: 'auditable_index'
      t.index :request_uuid
      t.index :created_at
    end
  end
end
