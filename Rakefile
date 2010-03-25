require 'rubygems'
require 'lib/morph'

begin
  require 'spec'
rescue LoadError
  puts "\nYou need to install the rspec gem to perform meta operations on this gem"
  puts "  sudo gem install rspec\n"
end

begin
  require 'echoe'

  Echoe.new("morph", Morph::VERSION) do |m|
    m.author = ["Rob McKinnon"]
    m.email = ["rob ~@nospam@~ rubyforge.org"]
    m.description = File.readlines("README").first
    m.rubyforge_name = "morph"
    m.rdoc_options << '--inline-source'
    m.dependencies = ["activesupport >=2.0.2"]
    m.dependencies = ["fastercsv >=1.5.0"]
    m.rdoc_pattern = ["README", "CHANGELOG", "LICENSE"]
  end

rescue LoadError
  puts "\nYou need to install the echoe gem to perform meta operations on this gem"
  puts "  sudo gem install echoe\n\n"
end

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -r ./lib/morph.rb"
end
