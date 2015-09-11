#!/usr/bin/env rake

require 'bundler/gem_helper'
require 'rspec/core/rake_task'
require 'rake/testtask'
require 'appraisal'

Bundler::GemHelper.install_tasks(:name => 'audited')

ADAPTERS = %w(active_record)

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

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

task :default => [:spec, :test]
