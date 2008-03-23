require 'hpricot'; require 'open-uri'; require 'morph'

# An example of Morph playing with Hpricot
class Hubbit

  include Morph

  def initialize name
    begin
      github_url = "http://github.com/#{name}"
      labels = Hpricot(open(github_url)) / 'label'

      labels.collect do |node|
        label = node.inner_text
        value = node.next_sibling.inner_text.strip

        morph(label, value) # magic morphing happening here!
      end
    rescue
      raise "Couldn't find hubbit with name: #{name}"
    end
  end
end

def Hubbit name
  Hubbit.new name
end

# why = Hubbit 'why'
# dhh = Hubbit 'dhh'

