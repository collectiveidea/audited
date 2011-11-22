# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.add_runtime_dependency(%q<rails>, [">= 3.0.3"])

  gem.authors = ["Brandon Keepers", "Kenneth Kalmer"]
  gem.email = 'brandon@opensoul.org'
  gem.required_rubygems_version = Gem::Requirement.new('>= 1.3.6')
  gem.files = `git ls-files`.split("\n")
  gem.homepage = %q{http://github.com/collectiveidea/acts_as_audited}
  gem.rdoc_options = ["--main", "README.rdoc", "--line-numbers", "--inline-source"]
  gem.require_paths = ["lib"]
  gem.name = 'acts_as_audited'
  gem.summary = %q{ActiveRecord extension that logs all changes to your models in an audits table}
  gem.test_files = `git ls-files -- spec/* test/*`.split("\n")
  gem.version = "2.0.1.beta1"
end

