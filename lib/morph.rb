require 'csv'

begin
  require 'active_support/core_ext/object/blank'
  require 'active_support/inflector'
  require 'active_support/core_ext/string/inflections'
  require 'active_support/core_ext/hash/conversions'
rescue Exception => e
  begin
    puts e.to_s
    require 'active_support'
  rescue Exception => e
    puts e.to_s
    require 'activesupport'
  end
end

module Chas
  @adding_morph_method = Hash.new {|hash,klass| hash[klass] = false } unless defined?(@adding_morph_method)
  @morph_methods = Hash.new {|hash,klass| hash[klass] = {} } unless defined?(@morph_methods)
  @morph_attributes = Hash.new {|hash,klass| hash[klass] = [] } unless defined?(@morph_attributes)
  @listeners = {}

  def self.register_listener listener
    @listeners[listener.object_id] = listener
  end

  def self.unregister_listener listener
    @listeners.delete(listener.object_id) if @listeners.has_key?(listener.object_id)
  end

  def self.morph_classes
    @morph_attributes.keys
  end

  def self.add_method klass, symbol
    if adding_morph_method?(klass)
      @morph_methods[klass][symbol] = true
      is_writer = symbol.to_s =~ /=$/
      unless is_writer
        @morph_attributes[klass] << symbol
        @listeners.values.each { |l| l.call klass, symbol }
      end
    end
  end

  def self.remove_method klass, symbol
    if @morph_methods[klass].has_key? symbol
      @morph_methods[klass].delete symbol
      is_writer = symbol.to_s =~ /=$/
      @morph_attributes[klass].delete(symbol) unless is_writer
    end
  end

  def self.morph_attributes klass
    if klass.superclass.respond_to?(:morph_attributes)
      @morph_attributes[klass] + klass.superclass.morph_attributes
    else
      @morph_attributes[klass] + []
    end
  end

  def self.morph_methods klass
    methods = @morph_methods[klass].keys.sort

    if klass.superclass.respond_to?(:morph_attributes)
      methods += klass.superclass.morph_methods
    end
    methods
  end

  private
  def self.adding_morph_method? klass
    @adding_morph_method[klass]
  end

  public
  def self.start_adding_morph_method klass
    @adding_morph_method[klass] = true
  end

  def self.finish_adding_morph_method klass
    @adding_morph_method[klass] = false
  end

  def self.add_morph_attribute klass, attribute
    start_adding_morph_method(klass)
    klass.send(:attr_accessor, attribute)
    finish_adding_morph_method(klass)
  end

  def self.morph_method_missing object, symbol, *args
    attribute = symbol.to_s.chomp '='
    attribute = attribute.to_sym

    if Object.instance_methods.include?(attribute)
      raise "'#{attribute}' is an instance_method on Object, cannot create accessor methods for '#{attribute}'"
    elsif argument_provided? args
      base = object.class
      add_morph_attribute base, attribute
      object.send(symbol, *args)
    end
  end

  def self.argument_provided? args
    args.size > 0
  end

  def self.convert_to_morph_class_name label
    name = label.to_s + ''
    name.tr!(',.:"\'/()\-*\\',' ')
    name.gsub!('%','percentage')
    name.strip!
    name.gsub!(/^(\d)/, '_\1')
    name.gsub!(/\s/,'_')
    name.squeeze!('_')
    name
  end

  def self.convert_to_morph_method_name label
    convert_to_morph_class_name label.to_s.downcase
  end

end

module Morph
  VERSION = '0.6.0' unless defined? Morph::VERSION

  class << self
    def classes
      Chas.morph_classes
    end

    def register_listener listener
      Chas.register_listener listener
    end

    def unregister_listener listener
      Chas.unregister_listener listener
    end

    def generate_migrations object, options={}
      options[:ignore] ||= []
      options[:belongs_to_id] ||= ''
      migrations = []
      name = object.class.name.demodulize.underscore
      add_migration name, object.morph_attributes, migrations, options
    end

    def from_csv csv, class_name, namespace=Morph
      objects = []
      CSV.parse(csv, { :headers => true }) do |row|
        object = object_from_name class_name, namespace
        row.each do |key, value|
          object.morph(key, value)
        end
        objects << object
      end
      objects
    end

    def from_tsv tsv, class_name, namespace=Morph
      lines = tsv.split("\n")
      attributes = lines[0].split("\t")
      lines = lines[1..(lines.length-1)]
      objects = []
      lines.each do |line|
        values = line.split("\t")
        object = object_from_name class_name, namespace
        attributes.each_with_index do |attribute, index|
          object.morph(attribute, values[index])
        end
        objects << object
      end
      objects
    end

    def from_xml xml, namespace=Morph
      hash = Hash.from_xml xml
      from_hash hash, namespace
    end

    def from_json json, root_key=nil, namespace=Morph
      require 'json' unless defined? JSON
      hash = JSON.parse json
      hash = { root_key => hash } if root_key
      from_hash hash, namespace
    end

    def from_hash hash, namespace=Morph
      if hash.keys.size == 1
        name = hash.keys.first

        case hash[name]
        when Hash
          object_from_hash hash[name], name, namespace
        when Array
          objects_from_array hash[name], name, namespace
        else
          raise 'hash root value must be a Hash or an Array'
        end
      else
        raise 'hash must have single key'
      end
    end

    def script_generate morphed_class, options={}
      name = morphed_class.name.to_s.split('::').last
      name = yield name if block_given?
      generator = options[:generator] || 'model'
      line = ["rails destroy #{generator} #{name}; rails generate #{generator} #{name}"]
      morphed_class.morph_methods.select{|m| not(m =~ /=$/) }.each {|attribute| line << " #{attribute}:string"}
      line.join('')
    end

    def included(base)
      base.extend ClassMethods
      base.send(:include, MethodMissing)
    end

    private
      def add_migration name, attributes, migrations, options
        migration = "./script/generate model #{name}#{options[:belongs_to_id]}"
        options[:belongs_to_id] = ''
        migrations << migration
        attributes = [attributes] if attributes.is_a?(String)
        attributes.to_a.sort{|a,b| a[0].to_s <=> b[0].to_s}.each do |attribute, value|
          case value
            when String
              attribute_name = attribute.to_s
              unless options[:ignore].include?(attribute_name)
                type = attribute_name[/date$/] ? 'date' : 'string'
                attribute_def = "#{attribute}:#{type}"
                migration.sub!(migration, "#{migration} #{attribute_def}")
              end            when Array
              options[:belongs_to_id] = " #{name}_id:integer"
              migrations = add_migration(attribute, '', migrations, options)
            when Hash
              options[:belongs_to_id] = " #{name}_id:integer"
              migrations = add_migration(attribute, value, migrations, options)
            when nil
              # ignore
            else
              puts 'not supported ' + value.inspect
          end
        end
        migrations
      end

      def class_constant namespace, name
        "#{namespace.name}::#{name}".constantize
      end

      def object_from_name name, namespace
        name = Chas.convert_to_morph_class_name(name).camelize
        begin
          type = class_constant namespace, name
        rescue NameError => e
          namespace.const_set name, Class.new
          type = class_constant namespace, name
          type.send(:include, Morph)
        end
        type.new
      end

      def object_from_hash hash, name, namespace
        object = object_from_name(name, namespace)
        add_to_object(object, hash, namespace)
      end

      def objects_from_array array, name, namespace
        if array.size > 0 && array.collect(&:class).uniq == [Hash]
          name = name.to_s.singularize
          array.map! { |hash| object_from_hash(hash, name, namespace) }
        else
          array
        end
      end

      def add_to_object object, attributes, namespace
        attributes.each do |name, value|
          name = name.to_s if name.is_a?(Symbol)
          attribute = name.gsub(':',' ').underscore

          value = value.to_time if defined?(XMLRPC::DateTime) && value.is_a?(XMLRPC::DateTime)

          case value
            when String, Date, Time, TrueClass, FalseClass, Integer, Float
              object.morph(attribute, value)
            when Array
              attribute = attribute.pluralize
              object.morph(attribute, objects_from_array(value, name, namespace))
            when Hash
              object.morph(attribute, object_from_hash(value, name, namespace))
            when NilClass
              object.morph(attribute, nil)
            else
              raise "cannot handle adding #{name} value of class: #{value.class.name}"
          end
        end
        object
      end
  end

  public

  module ClassMethods

    def morph_attributes
      Chas.morph_attributes(self)
    end

    def morph_methods
      Chas.morph_methods(self)
    end

    protected

    def method_added symbol
      Chas.add_method self, symbol
    end

    def method_removed symbol
      Chas.remove_method self, symbol
    end
  end

  module MethodMissing
    def method_missing symbol, *args
      is_writer = symbol.to_s =~ /=$/
      if is_writer
        Chas.morph_method_missing(self, symbol, *args)
      else
        super
      end
    end
  end

  #
  # Set attribute value(s). Adds accessor methods to class if
  # they are not already present.
  #
  # Can be called with a +string+ and a value, a +symbol+ and a value,
  # or with a +hash+ of attribute to value pairs. For example.
  #
  #   require 'rubygems'; require 'morph'
  #
  #   class Order; include Morph; end
  #
  #   order = Order.new
  #   order.morph :drink => 'tea', :sugars => 2, 'milk' => 'yes please'
  #   order.morph 'Payment type:', 'will wash dishes'
  #   order.morph :lemon, false
  #
  #   p order # -> #<Order:0x33c50c @lemon=false, @milk="yes please",
  #                @payment_type="will wash dishes", @sugars=2, @drink="tea">
  #
  def morph attributes_or_label, value=nil
    if attributes_or_label.is_a? Hash
      attributes_or_label.each { |a, v| morph(a, v) }
    else
      attribute = Chas.convert_to_morph_method_name(attributes_or_label)
      send("#{attribute}=".to_sym, value)
    end
  end

  def morph_attributes
    attributes = self.class.morph_attributes.inject({}) do |hash, attribute|
      unless attribute =~ /=\Z/
        symbol = attribute.to_sym
        value = send(symbol)

        value.each do |key, v|
          value[key] = v.morph_attributes if v.respond_to?(:morph_attributes)
        end if value.is_a? Hash

        value = value.collect {|v| v.respond_to?(:morph_attributes) ? v.morph_attributes : v } if value.is_a? Array
        value = value.morph_attributes if value.respond_to? :morph_attributes

        hash[symbol] = value
      end
      hash
    end
  end

end
