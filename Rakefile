#!/usr/bin/env rake

require 'bundler/gem_helper'
require 'rspec/core/rake_task'
require 'appraisal'

Bundler::GemHelper.install_tasks(:name => 'audited')
Bundler::GemHelper.install_tasks(:name => 'audited-activerecord')
Bundler::GemHelper.install_tasks(:name => 'audited-mongo_mapper')

ADAPTERS = %w(active_record mongo_mapper)

ADAPTERS.each do |adapter|
  desc "Run RSpec code examples for #{adapter} adapter"
  RSpec::Core::RakeTask.new(adapter) do |t|
    t.pattern = "spec/audited/adapters/#{adapter}/**/*_spec.rb"
  end
end

task :spec do
  ADAPTERS.each do |adapter|
    Rake::Task[adapter].invoke
  end
end

task :default => :spec
