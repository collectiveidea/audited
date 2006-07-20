
class Audit < ActiveRecord::Base
  belongs_to :person
  belongs_to :auditable, :polymorphic => true
  
  def self.audited_classes
    find_by_sql("SELECT DISTINCT auditable_type FROM #{table_name};").collect {|a| a.auditable_type}
  end
end