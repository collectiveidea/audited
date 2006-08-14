
class Audit < ActiveRecord::Base
  belongs_to :auditable, :polymorphic => true
  serialize :changes  
  
  def self.audited_classes
    find_by_sql("SELECT DISTINCT auditable_type FROM #{table_name};").collect {|a| a.auditable_type}
  end
end