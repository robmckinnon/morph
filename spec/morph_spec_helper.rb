# encoding: utf-8
require File.dirname(__FILE__) + '/../lib/morph'

module MorphSpecHelperMethods

  def initialize_morph
    @original_instance_methods = morphed_class.instance_methods
    @morph = morphed_class.new
  end

  def initialize_another_morph
    @more_original_instance_methods = another_morphed_class.instance_methods
    @another_morph = another_morphed_class.new
  end

  def remove_morph_methods
    morphed_class.instance_methods.each do |method|
      begin
        unless method.to_s[/received_message\?|pretty_print_inspect|should_not_receive|rspec_verify|unstub|rspec_reset|should_receive|as_null_object|stub_chain|stub\!|null_object?|stub/]
          remove_cmd = "remove_method :#{method}"
          morphed_class.class_eval(remove_cmd) unless (@original_instance_methods && @original_instance_methods.include?(method))
        end
      rescue Exception => e
        raise e.to_s + e.backtrace.join("\n") + '------' + (@original_instance_methods ? @original_instance_methods.sort.inspect : '')
      end

    end
  end

  def unload_morph_class
    Object.send(:remove_const, morphed_class.name.to_sym)
  end

  def remove_another_morph_methods
    another_morphed_class.instance_methods.each do |method|
      another_morphed_class.class_eval "remove_method :#{method}" unless @more_original_instance_methods.include?(method)
    end
  end

  def instance_methods klass=morphed_class
    klass.instance_methods
  end

  def morph_methods klass=morphed_class
    klass.morph_methods
  end

  def check_convert_to_morph_method_name label, method_name
    expect(Chas.convert_to_morph_method_name(label)).to eq method_name
  end

  def each_attribute
    if attribute
      yield attribute
    elsif attributes
      attributes.each {|a| yield a }
    end
  end
end

shared_examples_for "class with generated accessor methods added" do |klass|

  before do
    klass = morphed_class unless klass
  end

  it 'sets first attribute value correctly' do
    attribute = nil
    each_attribute {|a| attribute = a unless attribute}
    expect(@morph.send(attribute)).to eq value
  end

  it 'adds reader method to class instance_methods list' do
    if RUBY_VERSION >= "1.9"
      each_attribute { |a| expect(instance_methods(klass)).to include(a.to_s.to_sym) }
    else
      each_attribute { |a| expect(instance_methods(klass)).to include(a.to_s) }
    end
  end

  it 'adds writer method to class instance_methods list' do
    if RUBY_VERSION >= "1.9"
      each_attribute { |a| expect(instance_methods(klass)).to include("#{a}=".to_sym) }
    else
      each_attribute { |a| expect(instance_methods(klass)).to include("#{a}=") }
    end
  end

  it 'adds reader method to class morph_methods list' do
    if RUBY_VERSION >= "1.9"
      each_attribute { |a| expect(morph_methods(klass)).to include(a.to_s.to_sym) }
    else
      each_attribute { |a| expect(morph_methods(klass)).to include(a.to_s) }
    end
  end

  it 'adds writer method to class morph_methods list' do
    if RUBY_VERSION >= "1.9"
      each_attribute { |a| expect(morph_methods(klass)).to include("#{a}=".to_sym) }
    else
      each_attribute { |a| expect(morph_methods(klass)).to include("#{a}=") }
    end
  end

  it 'only has generated accessor methods in morph_methods list' do
    expect(morph_methods(klass).size).to eq expected_morph_methods_count
  end

end

shared_context 'single attribute value set' do |field, value|
  before(:all)  { initialize_morph }
  after(:all)  { unload_morph_class }

  let(:attribute) { field }
  let(:expected_morph_methods_count) { 2 }
  let(:value) { value }

  before { remove_morph_methods }
end
