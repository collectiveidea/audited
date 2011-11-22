require 'rake'
require 'rspec/core/rake_task'
require 'rake/testtask'
require 'bundler'
Bundler::GemHelper.install_tasks

$:.unshift File.expand_path('../lib', __FILE__)

require 'acts_as_audited'

desc 'Default: run specs and tests'
task :default => [:spec, :test]

RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = ["-c", "-f progress", "-r ./spec/spec_helper.rb"]
  t.pattern = 'spec/*_spec.rb'
end

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

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  puts "YARD (or a dependency) not available. Install it with: bundle install"
end

