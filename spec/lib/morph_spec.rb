require File.dirname(__FILE__) + '/../../lib/morph'
require File.dirname(__FILE__) + '/../morph_spec_helper'

describe Morph do
  describe "when writer method that didn't exist before is called with non-nil value" do
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

    it 'should return hash of attributes when morph_attributes called' do
      @morph.morph_attributes.should == {@attribute.to_sym => @quack}
    end

    it 'should generate rails model generator script line, with given model name' do
      @morphed_class.script_generate {|model_name| 'SomethingDifferent'}.should == "ruby script/destroy rspec_model SomethingDifferent; ruby script/generate rspec_model SomethingDifferent noise:string"
    end

    it 'should generate rails model generator script line' do
      @morphed_class.script_generate.should == "ruby script/destroy rspec_model ExampleMorph; ruby script/generate rspec_model ExampleMorph noise:string"
    end

    it 'should generate rails model generator script line' do
      @morphed_class.script_generate(:generator=>'model').should == "ruby script/destroy model ExampleMorph; ruby script/generate model ExampleMorph noise:string"
    end
  end

  describe "when writer method that didn't exist before is called with nil value" do
    before :each do
      remove_morph_methods
      @morph.noise= nil
      @attribute = 'noise'
    end

    it_should_behave_like "class without generated accessor methods added"
  end

  describe "when different writer method called on two different morph classes" do
    include MorphSpecHelperMethods

    before :each do
      initialize_morph
      initialize_another_morph
    end

    it 'should have morph_method return appropriate methods for each class' do
      @morph.every = 'where'
      @another_morph.no = 'where'

      @morphed_class.morph_methods.size.should == 2
      @another_morphed_class.morph_methods.size.should == 2

      @morphed_class.morph_methods.should == ['every','every=']
      @another_morphed_class.morph_methods.should == ['no','no=']
    end

    it 'should call morph_attributes on both objects, when one object has a reference to another' do
      @morph.every = 'which'
      @another_morph.way = 'but'
      @morph.loose = @another_morph

      attributes = @morph.morph_attributes
      attributes[:every].should == 'which'
      attributes[:loose].should == {:way => 'but'}
    end

    it 'should call morph_attributes on both objects, when one object has a reference to array of others' do
      @morph.every = 'which'
      @another_morph.way = 'but'
      @morph.loose = [@another_morph]

      attributes = @morph.morph_attributes
      attributes[:every].should == 'which'
      attributes[:loose].should == [{:way => 'but'}]
    end

    it 'should call morph_attributes on both objects, when one object has a reference to hash of others' do
      @morph.every = 'which'
      @another_morph.way = 'but'
      @morph.loose = { :honky_tonk => @another_morph}

      attributes = @morph.morph_attributes
      attributes[:every].should == 'which'
      attributes[:loose].should == { :honky_tonk => {:way => 'but'} }
    end

    after :each do
      remove_morph_methods
      remove_another_morph_methods
    end
  end

  describe "when class definition contains methods and morph is included" do
    include MorphSpecHelperMethods

    after :all do
      remove_morph_methods
      @morphed_class.class_eval "remove_method :happy"
    end

    it 'should not return methods defined in class in morph_methods list' do
      initialize_morph "class ExampleMorph\n include Morph\n def happy\n 'happy, joy, joy'\n end\n end"
      morph_methods.should be_empty
    end
  end

  describe "when writer method that didn't exist before is called with blank space attribute value" do
    before :each do
      remove_morph_methods
      @morph.noise= '   '
      @attribute = 'noise'
    end

    it_should_behave_like "class without generated accessor methods added"
  end

  describe 'when morph method used to set attribute value' do

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

  describe 'when morph method used to set an attribute value hash' do
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

    it 'should generate rails model generator script line' do
      @morphed_class.script_generate.should == "ruby script/destroy rspec_model ExampleMorph; ruby script/generate rspec_model ExampleMorph drink:string milk:string sugars:string"
    end

    it 'should generate rails model generator script line' do
      @morphed_class.script_generate(:generator=>'model').should == "ruby script/destroy model ExampleMorph; ruby script/generate model ExampleMorph drink:string milk:string sugars:string"
    end
  end

  describe "when morph method used to set unicode attribute name with a value" do
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

  describe "when morph method used to set japanese and latin unicode attribute name with a value" do
    before :each do
      $KCODE = "u"
      remove_morph_methods
      @age = 19
      @attribute = "ページビュー_graph"
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

  describe 'when morph method used to set blank space attribute value' do
    before :each do
      remove_morph_methods
      @morph.morph('Pizza', '   ')
      @attribute = 'pizza'
    end

    it_should_behave_like "class without generated accessor methods added"
  end

  describe 'when morph method used to set nil attribute value' do
    before :each do
      remove_morph_methods
      @morph.morph('Pizza', nil)
      @attribute = 'pizza'
    end

    it_should_behave_like "class without generated accessor methods added"
  end


  describe "when reader method that didn't exist before is called" do

    include MorphSpecHelperMethods

    it 'should raise NoMethodError' do
      initialize_morph
      lambda { @morph.noise }.should raise_error(/undefined method `noise'/)
    end
  end

  describe "when reader method called that didn't exist before is a class method" do

    include MorphSpecHelperMethods

    it 'should raise NoMethodError' do
      initialize_morph
      lambda { @morph.name }.should raise_error(/undefined method `name'/)
    end
  end

  describe "when writer method called matches a class reader method" do

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


  describe "when class= is called" do

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

  describe 'when passing block to morph_method_missing' do

    include MorphSpecHelperMethods
    before :all do initialize_morph; end
    after  :each do remove_morph_methods; end

    it 'should class_eval the block' do
      @morph.morph_method_missing(:chunky, 'bacon') do |base, attribute|
        base.class_eval "def #{attribute}; 'spinach'; end"
      end
      @morph.respond_to?(:chunky).should == true
      @morph.chunky.should == 'spinach'
      @morphed_class.class_eval "remove_method :chunky"
      lambda { @morph.chunky }.should raise_error
    end

    it 'should class_eval the block' do
      @morph.morph_method_missing :chunky, 'bacon' do |base, attribute|
        base.class_def(attribute) { 'spinach' }
      end
      @morph.respond_to?(:chunky).should == true
      @morph.chunky.should == 'spinach'
      @morphed_class.class_eval "remove_method :chunky"
      lambda { @morph.chunky }.should raise_error
    end

  end

  describe "when converting label text to morph method name" do

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

  describe 'creating from hash' do
    it 'should create classes and object instances with array of hashes' do
      h = {
        "CompanyDetails"=> {
          "SearchItems"=> [
            { "CompanyDate"=> '',
              "CompanyIndexStatus"=> '',
              "DataSet"=>"LIVE",
              "CompanyName"=>"CANONGROVE LIMITED",
              "CompanyNumber"=>"SC244777" },
            { "CompanyDate"=>"",
              "CompanyIndexStatus"=>"",
              "DataSet"=>"LIVE",
              "CompanyName"=>"CANONHALL ACCOUNTANCY LTD",
              "CompanyNumber"=>"05110715" }
          ]
        }
      }
      company_details = Morph.from_hash(h)
      company_details.search_items.first.class.name.should == 'Morph::SearchItem'
      company_details.search_items.first.data_set.should == 'LIVE'
      company_details.search_items.first.company_name.should == 'CANONGROVE LIMITED'
    end

    it 'should create classes and object instances' do
      h = {
        "CompanyDetails"=> {
          "RegAddress"=> {
              "AddressLine"=>["ST DAVID'S HOUSE", "WEST WING", "WOOD STREET", "CARDIFF CF10 1ES"]},
          "LastFullMemDate"=>"2002-03-25",
          "xsi:schemaLocation"=>"xmlgwdev.companieshouse.gov.uk/v1-0/schema/CompanyDetails.xsd",
          "HasBranchInfo"=>"0",
          "Mortgages"=> {
              "NumMortSatisfied"=>"0",
              "MortgageInd"=>"LT300",
              "NumMortOutstanding"=>"7",
              "NumMortPartSatisfied"=>"0",
              "NumMortCharges"=>"7"},
          "CompanyCategory"=>"Public Limited Company",
          "HasAppointments"=>"1",
          "SICCodes"=> {
              "SicText"=>"stadiums"},
          "Returns"=> {
              "Overdue"=>"NO",
              "DocumentAvailable"=>"1",
              "NextDueDate"=>"2003-04-22",
              "LastMadeUpDate"=>"2002-03-25"
           },
          "CountryOfOrigin"=>"United Kingdom",
          "CompanyStatus"=>"Active",
          "CompanyName"=>"MILLENNIUM STADIUM PLC",
          "InLiquidation"=>"0",
          "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
          "Accounts"=>{
              "Overdue"=>"NO",
              "DocumentAvailable"=>"1",
              "AccountCategory"=>"FULL",
              "NextDueDate"=>"2002-11-30",
              "LastMadeUpDate"=>"2001-04-30",
              "AccountRefDate"=>"0000-30-04"},
          "IncorporationDate"=>"1996-03-25",
          "CompanyNumber"=>"03176906",
          "xmlns"=>"http://xmlgw.companieshouse.gov.uk/v1-0"
        }
      }
      Object.const_set 'Company', Module.new
      Company.const_set 'House', Module.new

      company_details = Morph.from_hash(h, Company::House)
      company_details.class.name.should == 'Company::House::CompanyDetails'
      company_details.class.morph_methods.include?('last_full_mem_date').should be_true
      company_details.class.morph_methods.include?('accounts').should be_true

      company_details.accounts.class.name.should == 'Company::House::Accounts'
      company_details.accounts.overdue.should == 'NO'
      company_details.last_full_mem_date.should == "2002-03-25"
      company_details.sic_codes.sic_text.should == 'stadiums'
      company_details.reg_address.address_lines.should == ["ST DAVID'S HOUSE", "WEST WING", "WOOD STREET", "CARDIFF CF10 1ES"]

      list = Morph.generate_migrations company_details, :ignore=>['xmlns','xmlns_xsi','xsi_schema_location']
      list.size.should == 7
      list[0].should == "./script/generate model company_details company_category:string company_name:string company_number:string company_status:string country_of_origin:string has_appointments:string has_branch_info:string in_liquidation:string incorporation_date:date last_full_mem_date:date"
      list[1].should == './script/generate model accounts company_details_id:integer account_category:string account_ref_date:date document_available:string last_made_up_date:date next_due_date:date overdue:string'
      list[2].should == './script/generate model mortgages company_details_id:integer mortgage_ind:string num_mort_charges:string num_mort_outstanding:string num_mort_part_satisfied:string num_mort_satisfied:string'
      list[3].should == './script/generate model reg_address company_details_id:integer'
      list[4].should == './script/generate model address_lines reg_address_id:integer'
      list[5].should == './script/generate model returns company_details_id:integer document_available:string last_made_up_date:date next_due_date:date overdue:string'
      list[6].should == './script/generate model sic_codes company_details_id:integer sic_text:string'

      yaml = %Q|--- !ruby/object:Company::House::CompanyDetails
accounts: !ruby/object:Company::House::Accounts
  account_category: FULL
  account_ref_date: "0000-30-04"
  document_available: "1"
  last_made_up_date: "2001-04-30"
  next_due_date: "2002-11-30"
  overdue: "NO"
company_category: Public Limited Company
company_name: MILLENNIUM STADIUM PLC
company_number: 03176906
company_status: Active
country_of_origin: United Kingdom
has_appointments: "1"
has_branch_info: "0"
in_liquidation: "0"
incorporation_date: "1996-03-25"
last_full_mem_date: "2002-03-25"
mortgages: !ruby/object:Company::House::Mortgages
  mortgage_ind: LT300
  num_mort_charges: "7"
  num_mort_outstanding: "7"
  num_mort_part_satisfied: "0"
  num_mort_satisfied: "0"
reg_address: !ruby/object:Company::House::RegAddress
  address_lines:
  - ST DAVID'S HOUSE
  - WEST WING
  - WOOD STREET
  - CARDIFF CF10 1ES
returns: !ruby/object:Company::House::Returns
  document_available: "1"
  last_made_up_date: "2002-03-25"
  next_due_date: "2003-04-22"
  overdue: "NO"
sic_codes: !ruby/object:Company::House::SICCodes
  sic_text: stadiums
xmlns: http://xmlgw.companieshouse.gov.uk/v1-0
xmlns_xsi: http://www.w3.org/2001/XMLSchema-instance
xsi_schema_location: xmlgwdev.companieshouse.gov.uk/v1-0/schema/CompanyDetails.xsd|
    end
  end
end
