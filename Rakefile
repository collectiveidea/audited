#!/usr/bin/env rake

require 'rspec/core/rake_task'
require 'bundler/gem_helper'
require 'appraisal'

ADAPTERS = %w(active_record mongo_mapper)

ADAPTERS.each do |adapter|
  desc "Run RSpec code examples for #{adapter} adapter"
  RSpec::Core::RakeTask.new(adapter) do |t|
    t.pattern = "spec/audited/adapters/#{adapter}/**/*_spec.rb"
  end
end

RSpec::Core::RakeTask.new(:spec => ADAPTERS) do |t|
  t.pattern = 'spec/audited/*_spec.rb'
end

task :default => :spec

Bundler::GemHelper.install_tasks(:name => 'audited')
Bundler::GemHelper.install_tasks(:name => 'audited-activerecord')
Bundler::GemHelper.install_tasks(:name => 'audited-mongo_mapper')
