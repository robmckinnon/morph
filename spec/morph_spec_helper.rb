require File.dirname(__FILE__) + '/../lib/morph'

module MorphSpecHelperMethods

  def initialize_morph_class
    @morphed_class = eval 'class ExampleMorph; include Morph; end'
  end

  def initialize_morph
    initialize_morph_class
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
end

describe "class with generated accessor methods added", :shared => true do

  include MorphSpecHelperMethods
  before :all do initialize_morph; end
  after  :all do remove_morph_methods; end

  it 'should add reader method to class instance_methods list' do
    instance_methods.include?(@attribute).should == true
  end

  it 'should add writer method to class instance_methods list' do
    instance_methods.include?("#{@attribute}=").should == true
  end

  it 'should add reader method to class morph_methods list' do
    morph_methods.include?(@attribute).should == true
  end

  it 'should add writer method to class morph_methods list' do
    morph_methods.include?("#{@attribute}=").should == true
  end

  it 'should only have generated accessor methods in morph_methods list' do
    morph_methods.size.should == @expected_morph_methods_count
  end

  it 'should be able to print morph method declarations' do
    @morphed_class.print_morph_methods.should == %Q|attr_accessor :#{@attribute}|
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
    instance_methods.include?(@attribute).should == false
  end

  it 'should not add writer method to class instance_methods list' do
    instance_methods.include?("#{@attribute}=").should == false
  end

  it 'should not add reader method to class morph_methods list' do
    morph_methods.include?(@attribute).should == false
  end

  it 'should not add writer method to class morph_methods list' do
    morph_methods.include?("#{@attribute}=").should == false
  end

  it 'should have empty morph_methods list' do
    morph_methods.size.should == 0
  end
end
