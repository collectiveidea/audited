class AuditedMigrationGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      table_name = ARGV[1].blank? ? :audits : ARGV[1].to_sym
      m.migration_template 'migration.rb', 'db/migrate',
        :assigns => {:t => table_name}
    end
  end
end
