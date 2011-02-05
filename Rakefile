require 'rake'
require 'rspec/core/rake_task'
require 'rake/testtask'

$:.unshift File.expand_path('../lib', __FILE__)

require 'acts_as_audited'

desc 'Default: run specs and tests'
task :default => [:spec, :test]

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "acts_as_audited"
    gem.summary = %Q{ActiveRecord extension that logs all changes to your models in an audits table}
    gem.email = "brandon@opensoul.org"
    gem.homepage = "http://github.com/collectiveidea/acts_as_audited"
    gem.authors = ["Brandon Keepers"]
    gem.rdoc_options << '--main' << 'README.rdoc' << '--line-numbers' << '--inline-source'
    gem.version = ActsAsAudited::VERSION

    gem.add_dependency 'activerecord', '3.0.3'
    gem.add_development_dependency "rails", '3.0.3'
    gem.add_development_dependency "rspec-rails", '~> 2.4.0'
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  # Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: bundle install"
end

RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = ["-c", "-f progress", "-r ./spec/spec_helper.rb"]
  t.pattern = 'spec/*_spec.rb'
end

task :spec => :check_dependencies

RSpec::Core::RakeTask.new(:rcov) do |t|
  t.rcov = true
  t.rcov_opts =  %q[--exclude "spec"]
end

desc 'Test the acts_as_audited generators'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/*_test.rb'
  t.verbose = true
end

task :test => :check_dependencies

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  puts "YARD (or a dependency) not available. Install it with: bundle install"
end

