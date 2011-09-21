require 'morph'

require 'rubygems'; require 'nokogiri'; require 'open-uri'

# An example of Morph playing with Nokogiri
class Hubbit
  include Morph  # allows class to morph

  def initialize name
    doc = Nokogiri::HTML open("https://github.com/#{name}")

    profile_fields = doc.search('.vcard dt')

    profile_fields.each do |node|
      label = node.inner_text
      value = node.next_element.inner_text.strip

      morph(label, value)  # morph magic adds accessor methods!
    end
  end

  def member_since_date
    Date.parse member_since
  end
end

def Hubbit name
  Hubbit.new name
end

# why = Hubbit 'why'
# dhh = Hubbit 'dhh'
