require 'morph'
require 'open-uri'
require 'yaml'

# Example of morph used to implement a Ruby github API.
module Hubbit
end

module Hubbit::Listener
  def self.call klass, symbol
    klass.class_eval method_def(symbol) if url_method?(symbol)
  end

  private
  def self.url_method? symbol
    symbol.to_s[/_url$/]
  end

  def self.attribute symbol
    attribute = symbol.to_s.chomp('_url')
    "_#{attribute}"
  end

  def self.method_def symbol
    attribute = attribute(symbol)
"
def #{attribute}
  unless @#{attribute}
    url = send(:#{symbol}).split('{').first
    json = open(url).read
    @#{attribute} = Morph.from_json(json, :#{attribute.singularize}, Hubbit)
  end
  @#{attribute}
end"
  end
end

Morph.register_listener Hubbit::Listener

def Hubbit name
  url = "https://api.github.com/users/#{name}"
  json = open(url).read
  user = Morph.from_json(json, :user, Hubbit)
  user
end

dhh = Hubbit 'dhh'
