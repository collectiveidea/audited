require 'rake'
require 'load_multi_rails_rake_tasks'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run tests.'
task :default => :test

desc 'Test the acts_as_audited plugin'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the acts_as_audited plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = 'acts_as_audited'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end