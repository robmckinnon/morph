require 'rubygems'
require 'rubygems/package_task'
require 'rdoc/task'
require './lib/morph'

require 'rspec'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = %w(--format documentation --colour)
end

task :default => ['spec']

spec = Gem::Specification.new do |s|
  s.name              = 'morph'
  s.version           = Morph::VERSION
  s.summary           = 'Morph allows you to emerge Ruby class definitions from data or by calling assignment methods.'
  s.author            = 'Rob McKinnon'
  s.email             = 'rob ~@nospam@~ movingflow'
  s.homepage          = 'https://github.com/robmckinnon/morph'

  s.has_rdoc          = true
  s.extra_rdoc_files  = %w(README.md)
  s.rdoc_options      = %w(--main README.md)

  s.license           = 'MIT'
  s.files             = %w(CHANGELOG LICENSE) + Dir.glob('{lib}/**/*')
  s.require_paths     = ['lib']

  s.add_runtime_dependency('activesupport', '>= 4.1.11')
  s.add_development_dependency('rspec')
end

# This task actually builds the gem.
Gem::PackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "Build the gemspec file #{spec.name}.gemspec"
task :gemspec do
  file = File.dirname(__FILE__) + "/#{spec.name}.gemspec"
  File.open(file, 'w') {|f| f << spec.to_ruby }
end

# If you don't want to generate the .gemspec file, just remove this line.
task :package => :gemspec

# Generate documentation
RDoc::Task.new do |rd|
  rd.main = 'README.md'
  rd.rdoc_files.include('README.md', 'lib/**/*.rb')
  rd.rdoc_dir = 'rdoc'
end

desc 'Clear out RDoc and generated packages'
task :clean => [:clobber_rdoc, :clobber_package] do
  rm "#{spec.name}.gemspec"
end
