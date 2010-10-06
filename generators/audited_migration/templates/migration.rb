class <%= class_name %> < ActiveRecord::Migration
  def self.up
    create_table <%= t.inspect %>, :force => true do |t|
      t.column :auditable_id, :integer
      t.column :auditable_type, :string
      t.column :user_id, :integer
      t.column :user_type, :string
      t.column :username, :string
      t.column :action, :string
      t.column :changes, :text
      t.column :version, :integer, :default => 0
      t.column :comment, :string
      t.column :created_at, :datetime
    end
    
    add_index <%= t.inspect %>, [:auditable_id, :auditable_type]
    add_index <%= t.inspect %>, [:user_id, :user_type]
    add_index <%= t.inspect %>, :created_at  
  end

  def self.down
    drop_table <%= t.inspect %>
  end
end
