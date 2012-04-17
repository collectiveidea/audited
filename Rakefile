require 'rake'
require 'rspec/core/rake_task'
require 'rake/testtask'
require 'bundler'
require 'appraisal'

Bundler::GemHelper.install_tasks
Bundler.setup

ADAPTERS = %w(active_record mongo_mapper)

ADAPTERS.each do |adapter|
  desc "Run RSpec code examples for #{adapter} adapter"
  RSpec::Core::RakeTask.new(adapter) do |t|
    t.pattern = "spec/acts_as_audited/adapters/#{adapter}/**/*_spec.rb"
  end
end

RSpec::Core::RakeTask.new(:spec => ADAPTERS) do |t|
  t.pattern = 'spec/acts_as_audited/*_spec.rb'
end

task :default => :spec
