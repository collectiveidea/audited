  def self.up
    create_table :audits, :force => true do |t|
      t.column :auditable_id, :integer
      t.column :auditable_type, :string
      t.column :user_id, :integer
      t.column :action, :string
      t.column :changes, :text
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :audits
  end
