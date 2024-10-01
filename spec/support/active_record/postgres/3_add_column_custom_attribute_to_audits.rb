class AddColumnCustomAttributeToAudits < ActiveRecord::Migration[5.0]
  def change
    add_column :audits, :custom_attribute, :string
  end
end
