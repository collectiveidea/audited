# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.add_runtime_dependency "rails", "~> 3.0", ">= 3.0.3"

  gem.add_development_dependency 'mongo_mapper'

  gem.authors = ["Brandon Keepers", "Kenneth Kalmer", "Daniel Morrison", "Brian Ryckbost"]
  gem.email = 'daniel@collectiveidea.com  '
  gem.required_rubygems_version = Gem::Requirement.new('>= 1.3.6')
  gem.files = `git ls-files`.split("\n")
  gem.homepage = %q{https://github.com/collectiveidea/acts_as_audited}
  gem.rdoc_options = ["--main", "README.rdoc", "--line-numbers", "--inline-source"]
  gem.require_paths = ["lib"]
  gem.name = 'acts_as_audited'
  gem.summary = %q{ActiveRecord extension that logs all changes to your models in an audits table}
  gem.test_files = `git ls-files -- spec/* test/*`.split("\n")
  gem.version = "2.1.0"
end

