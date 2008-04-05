require File.dirname(__FILE__) + '/../lib/morph'
require File.dirname(__FILE__) + '/morph_spec_helper'

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

describe Morph, "when writer method that didn't exist before is called with nil value" do
  before :each do
    remove_morph_methods
    @morph.noise= nil
    @attribute = 'noise'
  end

  it_should_behave_like "class without generated accessor methods added"
end

describe Morph, "when writer method that didn't exist before is called with blank space attribute value" do
  before :each do
    remove_morph_methods
    @morph.noise= '   '
    @attribute = 'noise'
  end

  it_should_behave_like "class without generated accessor methods added"
end


describe Morph, 'when morph method used to set attribute value' do

  before :each do
    remove_morph_methods
    @value = '20 Mar 2008'
    @morph.morph('Reading', @value)
    @attribute = 'reading'
    @expected_morph_methods_count = 2
  end

  it_should_behave_like "class with generated accessor methods added"

  it 'should return assigned value when reader method called' do
    @morph.reading.should == @value
  end
end

describe Morph, 'when morph method used to set an attribute value hash' do
  before :each do
    remove_morph_methods
    @attributes = [:drink,:sugars,:milk]
    @morph.morph :drink => 'tea', :sugars => 2, :milk => 'yes please'
    @expected_morph_methods_count = 6
  end

  it_should_behave_like "class with generated accessor methods added"

  it 'should return assigned value when reader method called' do
    @morph.drink.should == 'tea'
    @morph.sugars.should == 2
    @morph.milk.should == 'yes please'
  end
end

describe Morph, "when morph method used to set unicode attribute name with a value" do
  before :each do
    $KCODE = "u"
    remove_morph_methods
    @age = 19
    @attribute = "年龄"
    @morph.morph(@attribute, @age)
    @expected_morph_methods_count = 2
  end

  after :all do
    $KCODE = "NONE"
  end

  it_should_behave_like "class with generated accessor methods added"

  it 'should return assigned value when reader method called' do
    @morph.send(@attribute.to_sym) == @age
  end
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


describe Morph, "when reader method that didn't exist before is called" do

  include MorphSpecHelperMethods

  it 'should raise NoMethodError' do
    initialize_morph
    lambda { @morph.noise }.should raise_error(/undefined method `noise'/)
  end
end

describe Morph, "when reader method called that didn't exist before is a class method" do

  include MorphSpecHelperMethods

  it 'should raise NoMethodError' do
    initialize_morph
    lambda { @morph.name }.should raise_error(/undefined method `name'/)
  end
end

describe Morph, "when writer method called matches a class reader method" do

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
=begin
describe Morph, 'when passing block to morph_method_missing' do

  include MorphSpecHelperMethods
  before :all do initialize_morph; end
  after  :all do remove_morph_methods; end

  it 'should class_eval the block' do
    @morph.morph_method_missing :noise, 'quack' do ||
      def chunky
        'bacon'
      end
    end
  end
end
=end
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
