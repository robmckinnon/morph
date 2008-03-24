$KCODE = "u"

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

describe Morph, "when reader method that didn't exist before is called" do
  before :each do
    remove_morph_methods
    @morph.noise
    @attribute = 'noise'
    @expected_morph_methods_count = 2
  end

  it_should_behave_like "class with generated accessor methods added"

  it 'should return nil if reader is called' do
    @morph.noise.should == nil
  end
end

describe Morph, "when writer method that didn't exist before is called with non-nil value" do
  before :each do
    remove_morph_methods
    @quack = 'quack'
    @morph.noise= @quack
    @attribute = 'noise'
    @expected_morph_methods_count = 2
  end

  it_should_behave_like "class with generated accessor methods added"

  it 'should return assigned value when reader method called' do
    @morph.noise.should == @quack
  end
end

describe Morph, "when writer method that didn't exist before is in unicode" do
  before :each do
    remove_morph_methods
    @age = 19
    @attribute = "年龄"
    @morph.morph(@attribute, @age)
    @expected_morph_methods_count = 2
  end

  it_should_behave_like "class with generated accessor methods added"

  it 'should return assigned value when reader method called' do
    @morph.send(@attribute.to_sym) == @age
  end
end

describe Morph, "when writer method that didn't exist before is called with nil value" do
  before :each do
    remove_morph_methods
    @morph.noise= nil
    @attribute = 'noise'
  end

  it_should_behave_like "class without generated accessor methods added"
end

describe Morph, 'when morph method used to set blank space attribute value' do
  before :each do
    remove_morph_methods
    @morph.morph('Pizza', '   ')
    @attribute = 'pizza'
  end

  it_should_behave_like "class without generated accessor methods added"
end

describe Morph, 'when morph method used to set nil attribute value' do
  before :each do
    remove_morph_methods
    @morph.morph('Pizza', nil)
    @attribute = 'pizza'
  end

  it_should_behave_like "class without generated accessor methods added"
end


describe Morph, 'when remove_morph_writers is called after a generated method has been added' do

  include MorphSpecHelperMethods
  before :all do initialize_morph; end
  after  :all do remove_morph_methods; end

  before :each do
    remove_morph_methods
    @morph.noise= 'quack'
    @attribute = 'noise'
    @morphed_class.remove_morph_writers
  end

  it 'should remove a morph generated writer method from morph_methods list' do
    morph_methods.include?('noise=').should == false
    morph_methods.size.should == 1
  end

  it 'should remove a morph generated writer method from class instance_methods list' do
    instance_methods.include?('noise=').should == false
  end

  it 'should be able to print morph method declarations' do
    @morphed_class.print_morph_methods.should == %Q|attr_reader :#{@attribute}|
  end

end

describe Morph, "when reader method called is a class method" do

  before :each do
    remove_morph_methods
    @morph.name
    @attribute = 'name'
    @expected_morph_methods_count = 2
  end

  it_should_behave_like "class with generated accessor methods added"
end

describe Morph, "when writer method called is a class method" do

  before :each do
    remove_morph_methods
    @value = 'Morph'
    @morph.name = @value
    @attribute = 'name'
    @expected_morph_methods_count = 2
  end

  it_should_behave_like "class with generated accessor methods added"

  it 'should return assigned value when reader method called' do
    @morph.name.should == @value
  end
end

describe Morph, "when class= is called" do

  include MorphSpecHelperMethods
  before :all do initialize_morph; end
  after  :all do remove_morph_methods; end

  it 'should throw exception if non nil object is passed' do
    lambda { @morph.class = 'Red' }.should raise_error(/cannot create accessor methods/)
  end

  it 'should throw exception if nil object is passed' do
    lambda { @morph.class = nil }.should raise_error(/cannot create accessor methods/)
  end
end

describe Morph, "when converting label text to morph method name" do

  include MorphSpecHelperMethods

  it 'should upper case to lower case' do
    check_convert_to_morph_method_name 'CaSe', 'case'
  end
  it 'should convert single space to underscorce' do
    check_convert_to_morph_method_name 'First reading', 'first_reading'
  end
  it 'should convert multiple spaces to single underscorce' do
    check_convert_to_morph_method_name "First  reading", 'first_reading'
  end
  it 'should convert tabs to single underscorce' do
    check_convert_to_morph_method_name "First\t\treading", 'first_reading'
  end
  it 'should convert new line chars to single underscorce' do
    check_convert_to_morph_method_name "First\r\nreading", 'first_reading'
  end
  it 'should remove leading and trailing whitespace new line chars to single underscorce' do
    check_convert_to_morph_method_name " \t\r\nFirst reading \t\r\n", 'first_reading'
  end
  it 'should remove trailing colon surrounded by whitespace' do
    check_convert_to_morph_method_name "First reading : ", 'first_reading'
  end
  it 'should remove parenthesis' do
    check_convert_to_morph_method_name 'Nav(GBX)', 'nav_gbx'
  end
  it 'should remove *' do
    check_convert_to_morph_method_name 'Change**', 'change'
  end
  it 'should convert % character to the text "percentage"' do
    check_convert_to_morph_method_name '% Change', 'percentage_change'
  end
  it 'should precede leading digit with an underscore character' do
    check_convert_to_morph_method_name '52w_high', '_52w_high'
  end
  it 'should handle unicode name' do
    check_convert_to_morph_method_name '年龄', '年龄'
  end
end

describe Morph, 'when morph method used to set attribute value and attribute name ends with colon' do

  before :each do
    remove_morph_methods
    @value = '20 Mar 2008'
    @morph.morph('First reading : ', @value)
    @attribute = 'first_reading'
    @expected_morph_methods_count = 2
  end

  it_should_behave_like "class with generated accessor methods added"

  it 'should return assigned value when reader method called' do
    @morph.first_reading.should == @value
  end
end

