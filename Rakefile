require 'rake'
require 'spec/rake/spectask'
require 'rake/rdoctask'

desc 'Default: run specs.'
task :default => :spec

desc 'Test the acts_as_audited plugin'
Spec::Rake::SpecTask.new(:spec) do |t|
  t.libs << 'lib'
  t.pattern = 'spec/**/*_spec.rb'
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