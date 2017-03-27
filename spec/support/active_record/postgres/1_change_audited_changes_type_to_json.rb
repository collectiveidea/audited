parent = Rails::VERSION::MAJOR == 4 ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
class ChangeAuditedChangesTypeToJson < parent
  def self.up
    remove_column :audits, :audited_changes
    add_column :audits, :audited_changes, :json
  end

  def self.down
    remove_column :audits, :audited_changes
    add_column :audits, :audited_changes, :text
  end
end
