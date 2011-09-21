require 'rubygems'
require './lib/morph'

begin
  require 'rspec'
rescue LoadError
  puts "\nYou need to install the rspec gem to perform meta operations on this gem"
  puts "  gem install rspec\n"
end

begin
  require 'echoe'

  Echoe.new("morph") do |m|
    m.author = ["Rob McKinnon"]
    m.email = ["rob ~@nospam@~ rubyforge.org"]
    m.summary = 'Morph mixin allows you to emerge class definitions via calling assignment methods.'
    m.description = File.readlines("README").first
    m.url = 'https://github.com/robmckinnon/morph'
    m.install_message = 'Read usage examples at: https://github.com/robmckinnon/morph#readme'
    m.version = Morph::VERSION
    m.project = "morph"
    m.rdoc_options << '--inline-source'
    m.rdoc_pattern = ["README", "CHANGELOG", "LICENSE"]
    m.runtime_dependencies = ["activesupport >=2.0.2"]
    m.development_dependencies = ['rspec','echoe']
  end

rescue LoadError
  puts "\nYou need to install the echoe gem to perform meta operations on this gem"
  puts "  gem install echoe\n\n"
end

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -r ./lib/morph.rb"
end
