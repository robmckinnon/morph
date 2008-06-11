require 'rubygems'; require 'hpricot'; require 'open-uri'; require 'morph'; require 'mofo'; require 'cgi'

# An example of Morph playing with Hpricot & Mofo using Google Search as a gateway
#
#==How it works
#
# 1) Locates WWR profile page through Google Search
# 2) Parses the content for HCard information using the mofo gem
# 3) Grabs the rest of the data using Hpricot
#
class WWR

  include Morph

  @@content = {}

  def initialize(name)
    begin
      url = "http://www.google.co.uk/search?hl=en&q=site%3Aworkingwithrails.com%2Fperson+%22#{CGI.escape(name)}%22+&btnI=745"

      @@content[url]  = (@@content[url] ? @@content[url] : open(url).read)
      content         = @@content[url]
      hcard           = HCard.find(:text => content)
      raise "Unable to extract HCard information" unless hcard.instance_of?(HCard)

      doc             = Hpricot.parse(content)
      morph('full_name',hcard.fn)
      morph('url',hcard.url)
      morph('about',hcard.note)
      morph('aliases',hcard.nickname)
      morph('photo_url',hcard.photo)
      morph('country',hcard.adr.country_name)
      morph('location',hcard.adr.locality)
      morph('for_hire',(true & doc.at('a[text() = "Available for hire"]')) )
      morph('authorities',(doc/"ul.authority li.tick").collect{|d| d.inner_text} )
      morph('popularity', doc.at('h3[text() = "Popularity"]').next_sibling.next_sibling.inner_text.to_f)
      morph('authority', doc.at('h3[text() = "Authority"]').next_sibling.next_sibling.inner_text.to_f)

      exp =  doc.at('h3[text() = "Experience"]').next_sibling.inner_text.split("\t").collect{|d| d.strip.chomp}
      morph('rails_experience',  exp.collect{|d| $1 if d =~ /Using Rails for(.*)/}.to_s.strip )
      morph('ruby_experience',   exp.collect{|d| $1 if d =~ /Using Ruby for(.*)/}.to_s.strip )

    rescue
      raise "Couldn't find WWR user with name: #{name}. #{$!}"
    end
  end
end

def WWR(name)
  WWR.new(name)
end
#
#  rob = WWR "Rob McKinnon"
#  rob.location
#   => "London"
#  rob.ruby_experience
#  => "5 years"
#  rob.authorities
#  => ["Presented at a Rails related event", "Attended a Rails related event", "Has published a Ruby gem", "Works professionally with Rails"]
#  rob.url
#  => "http://workingwithrails.com/person/5876-rob-mckinnon"
