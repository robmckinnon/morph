module Morph
  VERSION = "0.1.4"

  def self.included(base)
    base.extend ClassMethods
    base.send(:include, InstanceMethods)
    base.send(:include, MethodMissing)
  end

  module ClassMethods

    @@is_morphing = false
    @@morph_methods = {}

    def convert_to_morph_method_name label
      name = label.downcase.tr('()*',' ').gsub('%','percentage').strip.chomp(':').strip.gsub(/\s/,'_').squeeze('_')
      name = '_'+name if name =~ /^\d/
      name
    end

    def set_is_morphing true_or_false
      @@is_morphing = true_or_false
    end

    def method_added symbol
      @@morph_methods[symbol.to_s] = true if @@is_morphing
    end

    def method_removed symbol
      @@morph_methods.delete symbol.to_s if @@morph_methods.has_key? symbol.to_s
    end

    def class_def name, &block
      class_eval { define_method name, &block }
    end

    def morph_methods
      @@morph_methods.keys.sort
    end

    def remove_morph_writers
      writers = morph_methods.select { |m| m =~ /=\Z/ }
      writers.each do |writer|
        class_eval "remove_method :#{writer}"
      end
    end

    def print_morph_methods
      methods = morph_methods
      writers = methods.select { |m| m =~ /=\Z/ }
      readers = methods.reject { |m| m =~ /=\Z/ }

      accessors = readers.select { |m| writers.include? "#{m}=" }
      readers =   readers.reject { |m| accessors.include? m }
      writers =   writers.reject { |m| accessors.include? m.chomp('=') }

      attributes = accessors.collect { |attribute| "attr_accessor :#{attribute}\n" }
      attributes += readers.collect {  |attribute| "attr_reader :#{attribute}\n" }
      attributes += writers.collect {  |attribute| "attr_writer :#{attribute}\n" }

      attributes.join.chop
    end
  end

  module MethodMissing
    def method_missing symbol, *args
      is_writer = symbol.to_s =~ /=\Z/

      if is_writer
        morph_method_missing symbol, *args
      else
        super
      end
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
    def morph attributes, value=nil
      if attributes.is_a? Hash
        attributes.each { |a, v| morph(a, v) }
      else
        label = attributes
        attribute = label.is_a?(String) ? self.class.convert_to_morph_method_name(label) : label
        send("#{attribute}=".to_sym, value)
      end
    end

    def morph_method_missing symbol, *args, &block
      attribute = symbol.to_s.chomp '='
      if Object.instance_methods.include?(attribute)
        raise "'#{attribute}' is an instance_method on Object, cannot create accessor methods for '#{attribute}'"
      elsif args.size > 0
        value = args[0]
        empty_value = (value.nil? or (value.is_a?(String) && value.strip.size == 0))
        unless empty_value
          self.class.set_is_morphing true
          if block_given?
            yield self.class, attribute
          else
            self.class.class_eval "attr_accessor :#{attribute}"
            send(symbol, *args)
          end
          self.class.set_is_morphing false
        end
      end
    end
  end
end
