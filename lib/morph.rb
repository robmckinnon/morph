module Morph
  VERSION = "0.1.4"

  def self.included(base)
    base.extend ClassMethods
    base.send(:include, InstanceMethods)
    base.send(:include, MethodMissing)
  end

  module ClassMethods

    @@adding_morph_method = false
    @@morph_methods = {}

    def morph_methods
      @@morph_methods.keys.sort
    end

    def adding_morph_method= true_or_false
      @@adding_morph_method = true_or_false
    end

    def class_def name, &block
      class_eval { define_method name, &block }
    end

    protected

      def method_added symbol
        @@morph_methods[symbol.to_s] = true if @@adding_morph_method
      end

      def method_removed symbol
        @@morph_methods.delete symbol.to_s if @@morph_methods.has_key? symbol.to_s
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
        attribute = label.is_a?(String) ? convert_to_morph_method_name(label) : label
        send("#{attribute}=".to_sym, value)
      end
    end

    protected

      def morph_method_missing symbol, *args
        attribute = symbol.to_s.chomp '='

        if Object.instance_methods.include?(attribute)
          raise "'#{attribute}' is an instance_method on Object, cannot create accessor methods for '#{attribute}'"
        elsif argument_provided? args
          base = self.class
          base.adding_morph_method= true

          if block_given?
            yield base, attribute
          else
            base.class_eval "attr_accessor :#{attribute}"
            send(symbol, *args)
          end
          base.adding_morph_method= false
        end
      end

    private

      def argument_provided? args
        args.size > 0 && !args[0].nil? && !(args[0].is_a?(String) && args[0].strip.size == 0)
      end

      def convert_to_morph_method_name label
        name = label.downcase.tr('()*',' ').gsub('%','percentage').strip.chomp(':').strip.gsub(/\s/,'_').squeeze('_')
        name = '_'+name if name =~ /^\d/
        name
      end

  end
end
