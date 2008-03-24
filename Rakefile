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
  end

rescue LoadError
  puts "You need to install the echoe gem to perform meta operations on this gem"
end

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -r ./lib/morph.rb"
end

desc "Run spec runner"
task(:test) do
  files = FileList['spec/**/*_spec.rb']
  Spec::Runner::CommandLine.run(rspec_options)
  system "ruby spec/spec_runner.rb #{files} --format specdoc"
end
