require 'rubygems'
require 'spec'
require 'lib/morph'

begin
  require 'echoe'

  Echoe.new("morph", Morph::VERSION) do |morph|
    morph.author = ["Rob McKinnon"]
    morph.email = ["rob ~@nospam@~ rubyforge.org"]
    morph.description = File.readlines("README").first
    morph.rubyforge_name = "morph"
    morph.rdoc_options = ['--quiet', '--title', 'The Morph Reference', '--main', 'README', '--inline-source']
    morph.rdoc_files = ["README", "CHANGELOG", "LICENSE", "lib/morph.rb"]
  end

rescue LoadError
  puts "You need to install the echoe gem to perform meta operations on this gem"
end

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -r ./lib/morph.rb"
end
