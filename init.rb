begin
  require File.join(File.dirname(__FILE__), 'lib', 'morph') # From here
rescue LoadError
  require 'morph' # From gem
end
