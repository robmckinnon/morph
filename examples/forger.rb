require 'hpricot'; require 'open-uri'; require 'morph'

# An example of Morph playing with Hpricot
class Forger

  include Morph

  def initialize name
    begin
      ruby_forge_url = "http://rubyforge.org/users/#{name}"
      doc = Hpricot open(ruby_forge_url)
      table = doc.at('td[text() = "Personal Information"]').parent.parent
      values = table/'tr/td/strong'

      values.collect do |node|
        value = node.inner_text.strip
        label = node.at('../../td[1]').inner_text
        morph(label, value)
      end
    rescue
      raise "Couldn't find forger with name: #{name}"
    end
  end
end

def Forger name
  Forger.new name
end

#> why = Forger 'why'
#> dhh = Forger 'webster123'
