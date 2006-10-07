  def self.up
    create_table :audits, :force => true do |t|
      t.column :auditable_id, :integer
      t.column :auditable_type, :string
      t.column :user_id, :integer
      t.column :action, :string
      t.column :changes, :text
      t.column :created_at, :datetime
    end
    
    add_index :audits, :auditable_id
    add_index :audits, :auditable_type
    add_index :audits, :user_id
    add_index :audits, :created_at  
  end

  def self.down
    drop_table :audits
    
    remove_index :audits, :auditable_id
    remove_index :audits, :auditable_type
    remove_index :audits, :user_id
    remove_index :audits, :created_at
  end
