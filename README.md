Morph allows you to emerge Ruby class definitions from data or by calling assignment methods.

== Installing Morph

 gem install morph

To use Morph:

 require 'morph'

Tested to work with Ruby 1.8 - 2.3, JRuby 9, and Rubinius 3.

== Morph creating classes +from_json+

Here's an example showing Morph creating classes and objects from JSON:

 json = '{
   "id": "3599110793",
   "type": "PushEvent",
   "actor": {
     "id": 3447,
     "login": "robmckinnon",
     "url": "https://api.github.com/users/robmckinnon"
   },
   "repo": {
     "id": 5092,
     "name": "robmckinnon/morph",
     "url": "https://api.github.com/repos/robmckinnon/morph"
   }
 }'

 module Github; end

 type = :push_event
 namespace = Github

 event = Morph.from_json json, type, namespace

 # => <Github::PushEvent @id="3599110793", @type="PushEvent",
        @actor=#<Github::Actor:0x007faa0c86b790 @id=3447, @login="robmckinnon",
          @url="https://api.github.com/users/robmckinnon">,
        @repo=#<Github::Repo:0x007faa0c869198 @id=5092, @name="robmckinnon/morph",
          @url="https://api.github.com/repos/robmckinnon/morph">
      >

 event.class

 # => Github::PushEvent

 event.class.morph_attributes

 # => [:id, :type, :actor, :repo]

 event.actor.class

 # => Github::Actor

 event.repo.class

 # => Github::Repo

If namespace module not provided, new classes are created in Morph module.

 event = Morph.from_json json, type, namespace

 event.class

 # => Morph::PushEvent

== Morph creating classes +from_csv+

Here's an example showing Morph playing with CSV (comma-separated values):

 csv = %Q[name,party\nTed Roe,red\nAli Davidson,blue\nSue Smith,green]

 people = Morph.from_csv(csv, 'person')

 # => [#<Morph::Person @name="Ted Roe", @party="red">,
       #<Morph::Person @name="Ali Davidson", @party="blue">,
       #<Morph::Person @name="Sue Smith", @party="green">]

 people.last.party

 # => "green"

== Morph creating classes +from_tsv+

Here's example code showing Morph playing with TSV (tab-separated values):

 tsv = %Q[name\tparty\nTed Roe\tred\nAli Davidson\tblue\nSue Smith\tgreen]

 people = Morph.from_tsv(tsv, 'person')

 # => [#<Morph::Person @name="Ted Roe", @party="red">,
       #<Morph::Person @name="Ali Davidson", @party="blue">,
       #<Morph::Person @name="Sue Smith", @party="green">]

 people.last.party

 # => "green"

== Morph creating classes +from_xml+

Here's example code showing Morph playing with XML:

 xml = %Q[<?xml version="1.0" encoding="UTF-8"?>
 <councils type="array">
   <council code='1'>
     <name>Aberdeen City Council</name>
   </council>
   <council code='2'>
     <name>Allerdale Borough Council</name>
   </council>
 </councils>]

 councils = Morph.from_xml(xml)

 # => [#<Morph::Council @code="1", @name="Aberdeen City Council">,
       #<Morph::Council @code="2", @name="Allerdale Borough Council">]

 councils.first.name

 # => "Aberdeen City Council"

== Registering a listener to new class / methods via +register_listener+

You can use +register_listener+ to get callbacks when new methods on a class are
created.

For example given Morph used as a mixin:

 class Project; include Morph; end
 project = Project.new

Register listener:

 listener = -> (klass, method) do
   puts "class: #{klass.to_s} --- method: #{method}"
 end
 Morph.register_listener listener

Callback prints string as new methods are creaated via assignment calls:

 project.deadline = "11 11 2075"
 # class: Project --- method: deadline

 project.completed = true
 # class: Project --- method: completed

To unregister a listener use +unregister_listener+:

 Morph.unregister_listener listener

For an example of Morph's +register_listener+ being used to
[create a Github API](https://github.com/robmckinnon/hubbit/blob/master/lib/hubbit.rb)
see the [Hubbit module](https://github.com/robmckinnon/hubbit/blob/master/lib/hubbit.rb).

== Morph making sample Active Record line via +script_generate+

Time to generate an Active Record model? Get a sample script line like this:

 Morph.script_generate(Project)
 #=> "rails destroy model Project;
 #    rails generate model Project completed:string deadline:string

or specify the generator:

 Morph.script_generate(Hubbit, :generator => 'rspec_model')
 #=> "rails destroy rspec_model Project;
 #    rails generate rspec_model Project completed:string deadline:string

You'll have to edit this as it currently sets all data types to be string, and
doesn't understand associations.


== Morph setting hash of attributes via +morph+

 class Order; include Morph; end
 order = Order.new

How about adding a hash of attribute values?

 order.morph :drink => 'tea', :spoons_of_sugar => 2, :milk => 'prefer soya thanks'

Looks like we got 'em:

 order.drink  # => "tea"
 order.spoons_of_sugar  # => 2
 order.milk  # => "prefer soya thanks"


== Morph obtaining hash of attributes via +morph_attributes+

Create an item:

 class Item; include Morph; end
 item = Item.new
 item.morph :name => 'spinach', :cost => 0.50

Now an order:

 class Order; include Morph; end
 order = Order.new
 order.no = 123
 order.items = [item]

Want to retrieve all that as a nested hash of values? No problem:

 order.morph_attributes

 # => {:items=>[{:name=>"spinach", :cost=>0.5}], :no=>123}


== Last bits

See LICENSE for the terms of this software.

 .                                                     ,
 .                                                 ?7+~::+II~
 .                                                ?7:     ,:+7
 .                             777IIII777?        7:         :?7
 .                          =I=           I:      7?          ,+7
 .                         I?         ,,   77      7:           :I
 .                        =  ?7777   77  7   7      7+,          :7
 .                       7   777777 ~77+=77  I+      I?          ,7
 .                      :7  77  ~77  I   I7   7       ?:          ?
 .                      I   77   7,  7    7   :I       I          ?
 .                      7   ?77=7~    77777    7      ~+          ,+
 .                      7~                     7  :I7?~            7
 .                      =?                     7 ?I    ~I77=       I=
 .                       7    ?          :,   7  I7777,     7       7
 .                        ?    777?~~7777+    7              7~      7
 .                        ?7    ,777777=,   ,7                7      ,7
 .                          7=      ,      =7                 7:      7
 .                            +7         :7                    7      ,I
 .                             :7        ?~                   7?       7
 .                              7         7              ~II7~,        7
 .                              7         7  ,  =7777777?+,,,         I=
 .                            :7,          ~==,                       7
 .                       II~,,                                     77~
 .                    ,I?                                      +777
 .                   7+,                                 ~7777:
 .                 ==                               :77
 .               :7:                              ,7I
 .             7I                                 7
 .            I          ,7,                      7
 .          =7          77=7                      7
 .        ,7          7I   7                      7
 .        I,        I7     7                      7
 .       ?,       ,7       7,                     7
 .       7       7~        7,                     7
 .       7      ,7I        7                      7
 .       =+       =7       7                      ~=
 .        =7        7,     7                       7
 .         ,7,       ~7IIII7+,                     7
 .           +:              II                    I
 .            ?7              I?                   +~
 .              II,           +I                    7
 .                ~7          ,I                    7
 .                  7=        ~7                    7
 .                   ?7,     ~7+                    ?~
 .                     ~7777I=                      ,7
 .                         7:                        7
 .                         I                         7
 .                         I          ,:77I          7
 .                         I          :7             I
 .                         I                         =~
 .                         7               ,         ,7
 .                         +,         7    :         ,7
 .                          +         7    +          7
 .                          +         7    +         ,7
 .                          7         I    ?         ,7
 .                          7         +:   7         ,7
 .                          7         =+   7         ,7
 .                          7         :I   I         ,7
 .                          7         :I   7          7
 .                          7         :I   I          7
 .                          I,        ,7   I:         7
 .                          =+        ,7    ?         7
 .                          :?,       ,7    7,        7
 .                          I:        ,7    7,        ?
 .                         :7         ,7    7,        ,
 .                        +I,         :     ?         ,=
 .                       +=           ~     =~         7
 .                    :II,,           =      I         ?
 .                =I=                 ?      7,        :7
 .              II~                   I      7,         ,II
 .            7~                      ~7     7            ,=7
 .            =                       =7     I,             ::
 .            77II?==?II777777777777777      7~              7
 .                                            77+,,          7:
 .                                               777777+:,~777
 .
