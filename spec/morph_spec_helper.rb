require File.dirname(__FILE__) + '/../lib/morph'

module MorphSpecHelperMethods

  def initialize_morph_class code=nil
    code = 'class ExampleMorph; include Morph; end' unless code
    eval code
    @morphed_class = ExampleMorph
  end

  def initialize_morph code=nil
    initialize_morph_class code
    @original_instance_methods = @morphed_class.instance_methods
    @morph = @morphed_class.new
  end

  def remove_morph_methods
    @morphed_class.instance_methods.each do |method|
      @morphed_class.class_eval "remove_method :#{method}" unless @original_instance_methods.include?(method)
    end
  end

  def instance_methods
    @morphed_class.instance_methods
  end

  def morph_methods
    @morphed_class.morph_methods
  end

  def check_convert_to_morph_method_name label, method_name
    initialize_morph_class
    @morphed_class.convert_to_morph_method_name(label).should == method_name
  end

  def each_attribute
    if @attribute
      yield @attribute
    elsif @attributes
      @attributes.each {|a| yield a }
    end
  end
end

describe "class with generated accessor methods added", :shared => true do

  include MorphSpecHelperMethods
  before :all do initialize_morph; end
  after  :all do remove_morph_methods; end

  it 'should add reader method to class instance_methods list' do
    each_attribute { |a| instance_methods.should include(a.to_s) }
  end

  it 'should add writer method to class instance_methods list' do
    each_attribute { |a| instance_methods.should include("#{a}=") }
  end

  it 'should add reader method to class morph_methods list' do
    each_attribute { |a| morph_methods.should include(a.to_s) }
  end

  it 'should add writer method to class morph_methods list' do
    each_attribute { |a| morph_methods.should include("#{a}=") }
  end

  it 'should only have generated accessor methods in morph_methods list' do
    morph_methods.size.should == @expected_morph_methods_count
  end

end

describe "class without generated accessor methods added", :shared => true do
  include MorphSpecHelperMethods

  before :all do
    initialize_morph
  end

  after :all do
    remove_morph_methods
  end

  it 'should not add reader method to class instance_methods list' do
    instance_methods.should_not include(@attribute)
  end

  it 'should not add writer method to class instance_methods list' do
    instance_methods.should_not include("#{@attribute}=")
  end

  it 'should not add reader method to class morph_methods list' do
    morph_methods.should_not include(@attribute)
  end

  it 'should not add writer method to class morph_methods list' do
    morph_methods.should_not include("#{@attribute}=")
  end

  it 'should have empty morph_methods list' do
    morph_methods.size.should == 0
  end
end
