# Include DB adapters matching the version requirements in
# rails/activerecord/lib/active_record/connection_adapters/*adapter.rb

appraise "rails52" do
  gem "rails", "~> 5.2.8"
  gem "mysql2", ">= 0.4.4", "< 0.6.0"
  gem "pg", ">= 0.18", "< 2.0"
  gem "sqlite3", "~> 1.3.6"
  gem "psych", "~> 3.1"
  gem "loofah", "2.20.0"
end

appraise "rails60" do
  gem "rails", "~> 6.0.6"
  gem "mysql2", ">= 0.4.4"
  gem "pg", ">= 0.18", "< 2.0"
  gem "sqlite3", "~> 1.4"
end

appraise "rails61" do
  gem "rails", "~> 6.1.7"
  gem "mysql2", ">= 0.4.4"
  gem "pg", ">= 1.1", "< 2.0"
  gem "sqlite3", "~> 1.4"
end

appraise "rails70" do
  gem "rails", "~> 7.0.8"
  gem "mysql2", ">= 0.4.4"
  gem "pg", ">= 1.1"
  gem "sqlite3", "~> 1.4"
end

appraise "rails71" do
  gem "rails", "~> 7.1.3"
  gem "mysql2", ">= 0.4.4"
  gem "pg", ">= 1.1"
  gem "sqlite3", "~> 1.4"
end

appraise "rails72" do
  gem "rails", "~> 7.2.0"
  gem "mysql2", "~> 0.5"
  gem "pg", "~> 1.1"
  gem "sqlite3", ">= 1.4"
end

appraise "rails80" do
  gem "rails", "~> 8.0.0"
  gem "mysql2", "~> 0.5"
  gem "pg", "~> 1.1"
  gem "sqlite3", ">= 1.4"
end

appraise "rails_main" do
  gem "rails", github: "rails/rails", branch: "main"
  gem "mysql2", "~> 0.5"
  gem "pg", "~> 1.1"
  gem "sqlite3", ">= 2.0"
end
