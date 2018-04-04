class <%= migration_class_name %> < <%= migration_parent %>
  def change
    create_table :audits do |t|
      t.belongs_to :auditable, polymorphic: true, index: false
      t.index [:auditable_type, :auditable_id, :version],
              name: :index_audits_on_auditable_and_version

      t.references :associated, polymorphic: true,
                                index: { name: :index_audits_on_associated }

      t.references :user, type: :<%= options[:audited_user_id_column_type] %>,
                          polymorphic: true,
                          index: { name: :index_audits_on_user }

      t.string :username
      t.string :action
      t.<%= options[:audited_changes_column_type] %> :audited_changes
      t.integer :version, default: 0
      t.string :comment
      t.string :remote_address
      t.string :request_uuid, index: true
      t.datetime :created_at, index: true
    end
  end
end
