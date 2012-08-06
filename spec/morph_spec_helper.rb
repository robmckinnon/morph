# encoding: utf-8
require File.dirname(__FILE__) + '/../lib/morph'

module MorphSpecHelperMethods

  def initialize_morph_class code=nil
    code = 'class ExampleMorph; include Morph; end' unless code
    eval code
    @morphed_class = ExampleMorph
  end

  def initialize_second_morph_class code=nil
    code = 'class AnotherMorph; include Morph; end' unless code
    eval code
    @another_morphed_class = AnotherMorph
  end

  def initialize_morph code=nil
    initialize_morph_class code
    @original_instance_methods = @morphed_class.instance_methods
    @morph = @morphed_class.new
  end

  def initialize_another_morph
    initialize_second_morph_class
    @more_original_instance_methods = @another_morphed_class.instance_methods
    @another_morph = @another_morphed_class.new
  end

  def remove_morph_methods
    @morphed_class.instance_methods.each do |method|
      begin
        unless method.to_s[/received_message\?|should_not_receive|rspec_verify|unstub|rspec_reset|should_receive|as_null_object|stub_chain|stub\!|null_object?|stub/]
          remove_cmd = "remove_method :#{method}"
          @morphed_class.class_eval remove_cmd unless @original_instance_methods.include?(method)
        end
      rescue Exception => e
        raise e.to_s + '------' + @original_instance_methods.sort.inspect
      end

    end if @morphed_class
  end

  def remove_another_morph_methods
    @another_morphed_class.instance_methods.each do |method|
      @another_morphed_class.class_eval "remove_method :#{method}" unless @more_original_instance_methods.include?(method)
    end
  end

  def instance_methods
    @morphed_class.instance_methods
  end

  def morph_methods
    @morphed_class.morph_methods
  end

  def check_convert_to_morph_method_name label, method_name
    code = 'class ExampleMorph; include Morph; def convert_to_morph_method_name label; super; end; end'
    eval code
    ExampleMorph.new.convert_to_morph_method_name(label).should == method_name
  end

  def each_attribute
    if attribute
      yield attribute
    elsif @attributes
      @attributes.each {|a| yield a }
    end
  end
end

shared_examples_for "class with generated accessor methods added" do

  include MorphSpecHelperMethods
  before :all do initialize_morph; end
  after  :all do remove_morph_methods; end

  it 'should add reader method to class instance_methods list' do
    if RUBY_VERSION >= "1.9"
      each_attribute { |a| instance_methods.should include(a.to_s.to_sym) }
    else
      each_attribute { |a| instance_methods.should include(a.to_s) }
    end
  end

  it 'should add writer method to class instance_methods list' do
    if RUBY_VERSION >= "1.9"
      each_attribute { |a| instance_methods.should include("#{a}=".to_sym) }
    else
      each_attribute { |a| instance_methods.should include("#{a}=") }
    end
  end

  it 'should add reader method to class morph_methods list' do
    if RUBY_VERSION >= "1.9"
      each_attribute { |a| morph_methods.should include(a.to_s.to_sym) }
    else
      each_attribute { |a| morph_methods.should include(a.to_s) }
    end
  end

  it 'should add writer method to class morph_methods list' do
    if RUBY_VERSION >= "1.9"
      each_attribute { |a| morph_methods.should include("#{a}=".to_sym) }
    else
      each_attribute { |a| morph_methods.should include("#{a}=") }
    end
  end

  it 'should only have generated accessor methods in morph_methods list' do
    morph_methods.size.should == expected_morph_methods_count
  end

end

shared_examples_for "class without generated accessor methods added" do
  include MorphSpecHelperMethods

  before :all do
    initialize_morph
  end

  after :all do
    remove_morph_methods
  end

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
