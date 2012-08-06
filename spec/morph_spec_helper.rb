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
        unless method.to_s[/received_message\?|should_not_receive|rspec_verify|unstub|rspec_reset|should_receive|as_null_object|stub_chain|stub\!|null_object?|stub/]
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
    code = 'class ExampleMorph; include Morph; def convert_to_morph_method_name label; super; end; end'
    eval code
    ExampleMorph.new.convert_to_morph_method_name(label).should == method_name
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

  it 'should add reader method to class instance_methods list' do
    if RUBY_VERSION >= "1.9"
      each_attribute { |a| instance_methods(klass).should include(a.to_s.to_sym) }
    else
      each_attribute { |a| instance_methods(klass).should include(a.to_s) }
    end
  end

  it 'should add writer method to class instance_methods list' do
    if RUBY_VERSION >= "1.9"
      each_attribute { |a| instance_methods(klass).should include("#{a}=".to_sym) }
    else
      each_attribute { |a| instance_methods(klass).should include("#{a}=") }
    end
  end

  it 'should add reader method to class morph_methods list' do
    if RUBY_VERSION >= "1.9"
      each_attribute { |a| morph_methods(klass).should include(a.to_s.to_sym) }
    else
      each_attribute { |a| morph_methods(klass).should include(a.to_s) }
    end
  end

  it 'should add writer method to class morph_methods list' do
    if RUBY_VERSION >= "1.9"
      each_attribute { |a| morph_methods(klass).should include("#{a}=".to_sym) }
    else
      each_attribute { |a| morph_methods(klass).should include("#{a}=") }
    end
  end

  it 'should only have generated accessor methods in morph_methods list' do
    morph_methods(klass).size.should == expected_morph_methods_count
  end

end

shared_examples_for "class without generated accessor methods added" do

  it 'should not add reader method to class instance_methods list' do
    instance_methods.should_not include(attribute)
  end

  it 'should not add writer method to class instance_methods list' do
    instance_methods.should_not include("#{attribute}=")
  end

  it 'should not add reader method to class morph_methods list' do
    morph_methods.should_not include(attribute)
  end

  it 'should not add writer method to class morph_methods list' do
    morph_methods.should_not include("#{attribute}=")
  end

  it 'should have empty morph_methods list' do
    morph_methods.size.should == 0
  end
end
