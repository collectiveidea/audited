require 'rake'
require 'rspec/core/rake_task'
require 'rake/testtask'
require 'bundler'
Bundler::GemHelper.install_tasks

$:.unshift File.expand_path('../lib', __FILE__)

require 'acts_as_audited'

desc 'Default: run specs and tests'
task :default => [:spec, :test]

RSpec::Core::RakeTask.new(:spec)

desc 'Test the acts_as_audited generators'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/*_test.rb'
  t.verbose = true
end
