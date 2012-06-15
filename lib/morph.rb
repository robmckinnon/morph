if RUBY_VERSION >= "1.9"
  require 'csv'
end
begin
  # require 'active_support'
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

module Morph
  VERSION = "0.3.4" unless defined? Morph::VERSION

  class << self
    def generate_migrations object, options={}
      options[:ignore] ||= []
      options[:belongs_to_id] ||= ''
      migrations = []
      name = object.class.name.demodulize.underscore
      add_migration name, object.morph_attributes, migrations, options
    end

    def from_csv csv, class_name, namespace=Morph
      objects = []
      if !(RUBY_VERSION >= "1.9")
        begin
          require 'fastercsv'
        rescue LoadError
          puts "\nYou need to install the fastercsv gem to use Morph.from_csv() with Ruby 1.8"
          puts "  gem install fastercsv\n"
        end
      end

      csv_utility = (RUBY_VERSION >= "1.9") ? CSV : 'FasterCSV'.constantize
      csv_utility.parse(csv, { :headers => true }) do |row|
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

    def from_hash hash, namespace=Morph
      if hash.keys.size == 1
        key = hash.keys.first

        if hash[key].is_a? Hash
          attributes = hash[key]
          object = object_from_name(key, namespace)
          add_to_object object, attributes, namespace
          object
        elsif hash[key].is_a? Array
          array = hash[key]
          name = key.to_s.singularize
          objects_from_array(array, name, namespace)
        else
          raise 'hash root value must be a Hash or an Array'
        end
      else
        raise 'hash must have single key'
      end
    end

    def included(base)
      base.extend ClassMethods
      base.send(:include, InstanceMethods)
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
        name = name.to_s.camelize
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
          array.map! { |hash| object_from_hash(hash, name.singularize, namespace) }
        else
          array
        end
      end

      def add_to_object object, attributes, namespace
        attributes.each do |name, value|
          name = name.to_s if name.is_a?(Symbol)
          attribute = name.gsub(':',' ').underscore
          case value
            when String, Date, Time, TrueClass, FalseClass, Fixnum, Float
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

    @@adding_morph_method = Hash.new {|hash,klass| hash[klass] = false }
    @@morph_methods = Hash.new {|hash,klass| hash[klass] = {} }
    @@morph_attributes = Hash.new {|hash,klass| hash[klass] = [] }

    def morph_attributes
      @@morph_attributes[self] + []
    end

    def morph_methods
      if RUBY_VERSION >= "1.9"
        @@morph_methods[self].keys.sort.map(&:to_sym)
      else
        @@morph_methods[self].keys.sort
      end
    end

    def adding_morph_method= true_or_false
      @@adding_morph_method[self] = true_or_false
    end

    def class_def name, &block
      class_eval { define_method name, &block }
    end

    def script_generate options={}
      name = self.name.to_s.split('::').last
      name = yield name if block_given?
      generator = options[:generator] || 'model'
      line = ["rails destroy #{generator} #{name}; rails generate #{generator} #{name}"]
      morph_methods.select{|m| not(m =~ /=$/) }.each {|attribute| line << " #{attribute}:string"}
      line.join('')
    end

    protected

      def method_added symbol
        if @@adding_morph_method[self]
          @@morph_methods[self][symbol.to_s] = true
          is_writer = symbol.to_s =~ /=$/
          @@morph_attributes[self] << symbol unless is_writer
        end
      end

      def method_removed symbol
        if @@morph_methods[self].has_key? symbol.to_s
          @@morph_methods[self].delete symbol.to_s
          is_writer = symbol.to_s =~ /=$/
          @@morph_attributes[self].delete(symbol) unless is_writer
        end
      end

  end

  module MethodMissing
    def method_missing symbol, *args
      is_writer = symbol.to_s =~ /=$/
      is_writer ? morph_method_missing(symbol, *args) : super
    end
  end

  module InstanceMethods

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
        attribute = convert_to_morph_method_name(attributes_or_label)
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

    def morph_method_missing symbol, *args
      attribute = symbol.to_s.chomp '='
      if RUBY_VERSION >= "1.9"
        attribute = attribute.to_sym
      end

      if Object.instance_methods.include?(attribute)
        raise "'#{attribute}' is an instance_method on Object, cannot create accessor methods for '#{attribute}'"
      elsif argument_provided? args
        base = self.class
        base.adding_morph_method = true

        if block_given?
          yield base, attribute
        else
          # base.class_eval "attr_accessor :#{attribute}"
          base.class_eval "def #{attribute}; @#{attribute}; end; def #{attribute}=(value); @#{attribute} = value; end"
          send(symbol, *args)
        end
        base.adding_morph_method = false
      end
    end

    private

      def argument_provided? args
        args.size > 0 && !args[0].nil? && !(args[0].is_a?(String) && args[0].strip.size == 0)
      end

      def convert_to_morph_method_name label
        name = label.to_s.downcase.tr('()\-*',' ').gsub("'",' ').gsub('/',' ').gsub('%','percentage').strip.chomp(':').strip.gsub(/\s/,'_').squeeze('_')
        name = '_'+name if name =~ /^\d/
        name
      end
  end
end
