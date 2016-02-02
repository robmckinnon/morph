# encoding: utf-8
require File.dirname(__FILE__) + '/../morph_spec_helper'

describe Morph do
  include MorphSpecHelperMethods

  let(:attribute) { nil }

  def morph_class_code
    'class ExampleMorph; include Morph; end'
  end

  let(:another_morph_class_code)  { 'class AnotherMorph; include Morph; end' }
  let(:extended_morph_class_code) { 'class ExtendedMorph < ExampleMorph; include Morph; end' }

  def morphed_class
    eval(morph_class_code)
    ExampleMorph
  end

  let(:another_morphed_class) { eval(another_morph_class_code) ; AnotherMorph }
  let(:extended_morphed_class) { eval(extended_morph_class_code) ; ExtendedMorph }

  let(:original_instance_methods) { morphed_class.instance_methods }
  let(:more_original_instance_methods) { another_morphed_class.instance_methods }

  let(:morph) { morphed_class.new }
  let(:another_morph) { another_morphed_class.new }
  let(:extended_morph) { extended_morphed_class.new }

  describe "when writer method that didn't exist before is called with non-nil value" do
    before(:all) { initialize_morph }
    after(:all)  { unload_morph_class }

    let(:quack)     { 'quack' }
    let(:attribute) { 'noise' }
    let(:expected_morph_methods_count) { 2 }

    context do
      before do
        remove_morph_methods
        @morph.noise = quack
      end

      it_should_behave_like "class with generated accessor methods added"

      it 'should return assigned value when reader method called' do
        expect(@morph.noise).to eq quack
      end

      it 'should return hash of attributes when morph_attributes called' do
        expect(@morph.morph_attributes).to eq({attribute.to_sym => quack})
      end

      it 'should generate rails model generator script line, with given model name' do
        expect(Morph.script_generate(morphed_class) {|model_name| 'SomethingDifferent'}).to eq "rails destroy model SomethingDifferent; rails generate model SomethingDifferent noise:string"
      end

      it 'should generate rails model generator script line' do
        expect(Morph.script_generate(morphed_class)).to eq "rails destroy model ExampleMorph; rails generate model ExampleMorph noise:string"
      end

      it 'should generate rails model generator script line' do
        expect(Morph.script_generate(morphed_class, :generator => 'model')).to eq "rails destroy model ExampleMorph; rails generate model ExampleMorph noise:string"
      end
    end

    context 'and morph class is extended by class including Morph' do
      def self.extended_class
        eval('class ExampleMorph; include Morph; end')
        @morph = ExampleMorph.new
        @morph.noise = 'quack'
        eval('class ExtendedMorph < ExampleMorph; include Morph; end')
        ExtendedMorph
      end

      it_should_behave_like "class with generated accessor methods added", extended_class
    end
  end

  describe "when writer method that didn't exist before is called with nil value" do
    after(:all)  { unload_morph_class }

    let(:attribute) { 'noise' }

    before(:all) do
      initialize_morph
      @morph.noise= nil
    end

    it_should_behave_like "class without generated accessor methods added"
  end

  describe "when different writer method called on two different morph classes" do

    before do
      initialize_morph
      initialize_another_morph
    end

    it 'returns morph classes' do
      @another_morph.ex = 'machina'
      classes = Morph.classes.map(&:name)
      expect(classes).to include('ExampleMorph')
      expect(classes).to include('AnotherMorph')
    end

    it 'should have morph_method return appropriate methods for each class' do
      @morph.every = 'where'
      @another_morph.no = 'where'

      expect(morphed_class.morph_methods.size).to eq 2
      expect(another_morphed_class.morph_methods.size).to eq 2

      if RUBY_VERSION >= "1.9"
        expect(morphed_class.morph_methods).to eq [:every,:every=]
        expect(another_morphed_class.morph_methods).to eq [:no,:no=]
      else
        expect(morphed_class.morph_methods).to eq ['every','every=']
        expect(another_morphed_class.morph_methods).to eq ['no','no=']
      end
    end

    it 'sends callbacks to registered listener' do
      listener = double
      Morph.register_listener listener
      expect(listener).to receive(:call).with(ExampleMorph, :every)
      @morph.every = 'which'
      Morph.unregister_listener listener
    end

    it 'should call morph_attributes on both objects, when one object has a reference to another' do
      @morph.every = 'which'
      @another_morph.way = 'but'
      @morph.loose = @another_morph

      attributes = @morph.morph_attributes
      expect(attributes[:every]).to eq 'which'
      expect(attributes[:loose]).to eq :way => 'but'
    end

    it 'should call morph_attributes on both objects, when one object has a reference to array of others' do
      @morph.every = 'which'
      @another_morph.way = 'but'
      @morph.loose = [@another_morph]

      attributes = @morph.morph_attributes
      expect(attributes[:every]).to eq 'which'
      expect(attributes[:loose]).to eq [{:way => 'but'}]
    end

    it 'should call morph_attributes on both objects, when one object has a reference to hash of others' do
      @morph.every = 'which'
      @another_morph.way = 'but'
      @morph.loose = { :honky_tonk => @another_morph}

      attributes = @morph.morph_attributes
      expect(attributes[:every]).to eq 'which'
      expect(attributes[:loose]).to eq({ :honky_tonk => {:way => 'but'} })
      attributes.delete(:every)
      attributes = @morph.morph_attributes
      expect(attributes[:every]).to eq 'which'

      attributes = @morph.class.morph_attributes
      expect(attributes).to eq [:every, :loose]
      attributes.delete(:every)
      attributes = @morph.class.morph_attributes
      expect(attributes).to eq [:every, :loose]
    end

    after do
      remove_morph_methods
      remove_another_morph_methods
    end
  end

  describe "when class definition contains methods and morph is included" do
    before { initialize_morph }
    after  { unload_morph_class }

    let(:morph_class_code) { "class ExampleMorph\n include Morph\n def happy\n 'happy, joy, joy'\n end\n end" }

    it 'should not return methods defined in class in morph_methods list' do
      expect(morph_methods).to be_empty
    end
  end

  describe "when writer method that didn't exist before is called with blank space attribute value" do
    after(:all)  { unload_morph_class }

    let(:attribute) { 'noise' }

    before(:all) do
      initialize_morph
      @morph.noise = '   '
    end

    it_should_behave_like "class without generated accessor methods added"
  end

  describe 'when morph method used to set attribute value' do
    before(:all) { initialize_morph }
    after(:all)  { unload_morph_class }

    let(:attribute) { 'reading' }
    let(:value)     { '20 Mar 2008' }
    let(:expected_morph_methods_count) { 2 }

    before do
      remove_morph_methods
      @morph.morph('Reading', value)
    end

    it_should_behave_like "class with generated accessor methods added"

    it 'should return assigned value when reader method called' do
      expect(@morph.reading).to eq value
    end
  end

  describe 'when morph method used to set an attribute value hash' do
    before(:all) { initialize_morph }
    after(:all)  { unload_morph_class }

    let(:expected_morph_methods_count) { 6 }
    let(:attributes) { [:drink,:sugars,:milk] }

    before do
      remove_morph_methods
      @morph.morph :drink => 'tea', :sugars => 2, :milk => 'yes please'
    end

    it_should_behave_like "class with generated accessor methods added"

    it 'should return assigned value when reader method called' do
      expect(@morph.drink).to eq 'tea'
      expect(@morph.sugars).to eq 2
      expect(@morph.milk).to eq 'yes please'
    end

    it 'should generate rails model generator script line' do
      expect(Morph.script_generate(morphed_class)).to eq "rails destroy model ExampleMorph; rails generate model ExampleMorph drink:string milk:string sugars:string"
    end

    it 'should generate rails model generator script line' do
      expect(Morph.script_generate(morphed_class, :generator=>'model')).to eq "rails destroy model ExampleMorph; rails generate model ExampleMorph drink:string milk:string sugars:string"
    end
  end

=begin
  describe "when morph method used to set unicode attribute name with a value" do
    before(:all) { initialize_morph }
    after(:all)  { unload_morph_class }

    before do
      $KCODE = "u" unless RUBY_VERSION >= "1.9"
      remove_morph_methods
      @age = 19
      @attribute = "年龄"
      @morph.morph(@attribute, @age)
      @expected_morph_methods_count = 2
    end

    after :all do
      $KCODE = "NONE" unless RUBY_VERSION >= "1.9"
    end

    it_should_behave_like "class with generated accessor methods added"

    it 'should return assigned value when reader method called' do
      @morph.send(@attribute.to_sym) == @age
    end
  end
  describe "when morph method used to set japanese and latin unicode attribute name with a value" do
    before :all do initialize_morph; end
    after  :all do unload_morph_class; end

    before do
      $KCODE = "u" unless RUBY_VERSION >= "1.9"
      remove_morph_methods
      @age = 19
      @attribute = "ページビュー_graph"
      @morph.morph(@attribute, @age)
      @expected_morph_methods_count = 2
    end

    after :all do
      $KCODE = "NONE" unless RUBY_VERSION >= "1.9"
    end

    it_should_behave_like "class with generated accessor methods added"

    it 'should return assigned value when reader method called' do
      @morph.send(@attribute.to_sym) == @age
    end
  end
=end

  describe 'when morph method used to set blank space attribute value' do
    after(:all)  { unload_morph_class }

    let(:attribute) { 'pizza' }

    before(:all) do
      initialize_morph
      @morph.morph('Pizza', '   ')
    end

    it_should_behave_like "class without generated accessor methods added"
  end

  describe 'when morph method used to set nil attribute value' do
    after(:all)  { unload_morph_class }

    let(:attribute) { 'pizza' }

    before(:all) do
      initialize_morph
      @morph.morph('Pizza', nil)
    end

    it_should_behave_like "class without generated accessor methods added"
  end


  describe "when reader method that didn't exist before is called" do

    it 'should raise NoMethodError' do
      initialize_morph
      expect { @morph.noise }.to raise_error(NoMethodError, /undefined method `noise'/)
    end
  end

  describe "when reader method called that didn't exist before is a class method" do

    it 'should raise NoMethodError' do
      initialize_morph
      expect { @morph.name }.to raise_error(NoMethodError, /undefined method `name'/)
    end
  end

  describe "when writer method called matches a class reader method" do

    before(:all) { initialize_morph }
    after(:all)  { unload_morph_class }

    let(:attribute) { 'name' }
    let(:value)     { 'Morph' }
    let(:expected_morph_methods_count) { 2 }

    before do
      remove_morph_methods
      @morph.name = value
    end

    it_should_behave_like "class with generated accessor methods added"

    it 'should return assigned value when reader method called' do
      expect(@morph.name).to eq value
    end
  end


  describe "when class= is called" do
    before(:all) { initialize_morph }
    after(:all)  { unload_morph_class }

    it 'should throw exception if non nil object is passed' do
      expect { @morph.class = 'Red' }.to raise_error(/cannot create accessor methods/)
    end

    it 'should throw exception if nil object is passed' do
      expect { @morph.class = nil }.to raise_error(/cannot create accessor methods/)
    end
  end

  describe 'when calling method_missing' do
    before(:all) { initialize_morph }
    after(:all)  { unload_morph_class }

    it 'should class_eval the block' do
      @morph.method_missing(:'chunky=', 'bacon')
      expect(@morph.respond_to?(:chunky)).to eq true
      expect(@morph.chunky).to eq 'bacon'
      morphed_class.class_eval "remove_method :chunky"
      expect { @morph.chunky }.to raise_error(NoMethodError)
    end

  end

  describe "when converting label text to morph method name" do

    it 'coverts dash to underscore' do
      check_convert_to_morph_method_name 'hi-time', 'hi_time'
    end

    it 'converts upper case to lower case' do
      check_convert_to_morph_method_name 'CaSe', 'case'
    end

    it 'converts single space to underscorce' do
      check_convert_to_morph_method_name 'First reading', 'first_reading'
    end

    it 'converts multiple spaces to single underscorce' do
      check_convert_to_morph_method_name "First  reading", 'first_reading'
    end

    it 'converts tabs to single underscorce' do
      check_convert_to_morph_method_name "First\t\treading", 'first_reading'
    end

    it 'converts new line chars to single underscorce' do
      check_convert_to_morph_method_name "First\r\nreading", 'first_reading'
    end

    it 'removes leading and trailing whitespace new line chars to single underscorce' do
      check_convert_to_morph_method_name " \t\r\nFirst reading \t\r\n", 'first_reading'
    end

    it 'removes trailing colon surrounded by whitespace' do
      check_convert_to_morph_method_name "First reading : ", 'first_reading'
    end

    it 'removes parenthesis' do
      check_convert_to_morph_method_name 'Nav(GBX)', 'nav_gbx'
    end

    it 'removes *' do
      check_convert_to_morph_method_name 'Change**', 'change'
    end

    it 'converts % character to the text "percentage"' do
      check_convert_to_morph_method_name '% Change', 'percentage_change'
    end

    it 'precedes leading digit with an underscore character' do
      check_convert_to_morph_method_name '52w_high', '_52w_high'
    end

    it 'handles unicode name' do
      check_convert_to_morph_method_name '年龄', '年龄'
    end

    it 'removes forward and back slash' do
      check_convert_to_morph_method_name 'ready/steady\go', 'ready_steady_go'
    end

    it 'removes single and double quotes' do
      check_convert_to_morph_method_name 'ready"steady\'go', 'ready_steady_go'
    end

    it 'removes dots and commas' do
      check_convert_to_morph_method_name 'config_for.rb,', 'config_for_rb'
    end
  end

  let(:search_items_hash) do
    {
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
  end

  let(:company_details_hash) do
    {
      "CompanyDetails"=> {
        :RegAddress=> {
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
  end

  shared_examples 'creates correctly' do
    it 'should create classes and object instances with array of hashes' do
      items = company_details_search.is_a?(Array) ? company_details_search : company_details_search.search_items

      expect(items.first.class.name).to eq 'Morph::SearchItem'
      expect(items.first.data_set).to eq 'LIVE'
      expect(items.first.company_name).to eq 'CANONGROVE LIMITED'
    end

    it 'should create classes and object instances' do
      expect(company_details.class.name).to eq 'Company::House::CompanyDetails'
      morph_methods = company_details.class.morph_methods
      if RUBY_VERSION >= "1.9"
        expect(morph_methods.include?(:last_full_mem_date)).to be true
        expect(morph_methods.include?(:accounts)).to be true
        morph_methods.delete(:accounts)
        expect(morph_methods.include?(:accounts)).to be false
        morph_methods = company_details.class.morph_methods
        expect(morph_methods.include?(:accounts)).to be true
      else
        expect(morph_methods.include?('last_full_mem_date')).to be true
        expect(morph_methods.include?('accounts')).to be true
        morph_methods.delete('accounts')
        expect(morph_methods.include?('accounts')).to be false
        morph_methods = company_details.class.morph_methods
        expect(morph_methods.include?('accounts')).to be true
      end

      expect(company_details.accounts.class.name).to eq 'Company::House::Accounts'
      expect(company_details.accounts.overdue).to eq 'NO'
      expect(company_details.last_full_mem_date).to eq "2002-03-25"
      expect(company_details.sic_codes.sic_text).to eq 'stadiums'
      expect(company_details.reg_address.address_lines).to eq ["ST DAVID'S HOUSE", "WEST WING", "WOOD STREET", "CARDIFF CF10 1ES"]

      list = Morph.generate_migrations company_details, :ignore=>['xmlns','xmlns_xsi','xsi_schema_location']
      expect(list.size).to eq 7
      expect(list[0]).to eq "./script/generate model company_details company_category:string company_name:string company_number:string company_status:string country_of_origin:string has_appointments:string has_branch_info:string in_liquidation:string incorporation_date:date last_full_mem_date:date"
      expect(list[1]).to eq './script/generate model accounts company_details_id:integer account_category:string account_ref_date:date document_available:string last_made_up_date:date next_due_date:date overdue:string'
      expect(list[2]).to eq './script/generate model mortgages company_details_id:integer mortgage_ind:string num_mort_charges:string num_mort_outstanding:string num_mort_part_satisfied:string num_mort_satisfied:string'
      expect(list[3]).to eq './script/generate model reg_address company_details_id:integer'
      expect(list[4]).to eq './script/generate model address_lines reg_address_id:integer'
      expect(list[5]).to eq './script/generate model returns company_details_id:integer document_available:string last_made_up_date:date next_due_date:date overdue:string'
      expect(list[6]).to eq './script/generate model sic_codes company_details_id:integer sic_text:string'

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

  describe 'creating from hash' do
    let(:company_details_search) { Morph.from_hash(search_items_hash) }

    let(:company_details) do
      Object.const_set 'Company', Module.new
      Company.const_set 'House', Module.new
      Morph.from_hash(company_details_hash, Company::House)
    end

    include_examples 'creates correctly'
  end

  describe 'creating from json' do
    require 'json'

    let(:company_details_search) { Morph.from_json(search_items_hash.to_json) }

    let(:company_details) do
      Object.const_set 'Company', Module.new unless defined? Company
      Company.const_set 'House', Module.new unless defined? Company::House
      Morph.from_json(company_details_hash.to_json, nil, Company::House)
    end

    include_examples 'creates correctly'
  end

  describe 'creating from json that is not single key hash' do
    require 'json'

    let(:company_details_search) do
      array = search_items_hash['CompanyDetails']['SearchItems']
      Morph.from_json(array.to_json, 'SearchItems')
    end

    let(:company_details) do
      Object.const_set 'Company', Module.new unless defined? Company
      Company.const_set 'House', Module.new unless defined? Company::House
      multi_key_hash = company_details_hash['CompanyDetails']
      Morph.from_json(multi_key_hash.to_json, 'CompanyDetails', Company::House)
    end

    include_examples 'creates correctly'
  end

  describe 'creating from xml' do

    def check_councils councils, class_name
      expect(councils.class).to eq Array
      expect(councils.size).to eq 2
      expect(councils.first.class.name).to eq class_name
      expect(councils.first.name).to eq 'Aberdeen City Council'
      expect(councils.last.name).to eq 'Allerdale Borough Council'
    end

    it 'should create classes and object instances' do
      councils = Morph.from_xml(xml)
      check_councils councils, 'Morph::Council'
    end

    describe 'when module name is supplied' do
      it 'should create classes and object instances' do
        Object.const_set 'Ppc', Module.new
        councils = Morph.from_xml(xml, Ppc)
        check_councils councils, 'Ppc::Council'
      end
    end

    def xml
%Q[<?xml version="1.0" encoding="UTF-8"?>
<councils type="array">
  <council code='1'>
    <name>Aberdeen City Council</name>
  </council>
  <council code='2'>
    <name>Allerdale Borough Council</name>
  </council>
</councils>]
    end
  end

  describe 'creating from' do

    def check_councillors councillors, class_name, nil_value=''
      expect(councillors.class).to eq Array
      expect(councillors.size).to eq 2
      councillor = councillors.first
      expect(councillor.class.name).to eq class_name
      expect(councillor.name).to eq 'Ted Roe'
      expect(councillor.party).to eq 'labour'
      expect(councillor.councillors).to eq 'Councillor for Stretford Ward'
      expect(councillor.councils).to eq 'Trafford Council'
      expect(councillor.respond_to?(:council_experience)).to be false

      councillor = councillors.last
      expect(councillor.name).to eq 'Ali Davidson'
      expect(councillor.party).to eq 'labour'
      expect(councillor.councillors).to eq nil_value
      expect(councillor.councils).to eq 'Basildon District Council'
      expect(councillor.respond_to?(:council_experience)).to be false
    end

    describe 'tsv (tab separated value)' do
      describe 'when class name is supplied' do
        it 'should create classes and object instances' do
          councillors = Morph.from_tsv(tsv, 'Councillor')
          check_councillors councillors, 'Morph::Councillor'
        end
      end

      describe 'when class name and module name is supplied' do
        it 'should create classes and object instances' do
          Object.const_set 'Ppc', Module.new unless defined? Ppc
          councillors = Morph.from_tsv(tsv, 'Councillor', Ppc)
          check_councillors councillors, 'Ppc::Councillor'
        end
      end

      def tsv
  %Q[name	party	councillors	councils	council_experience
Ted Roe	labour	Councillor for Stretford Ward	Trafford Council
Ali Davidson	labour		Basildon District Council
]
      end
    end

    describe 'csv (comma separated value)' do
      describe 'when class name is supplied' do
        it 'should create classes and object instances' do
          councillors = Morph.from_csv(csv, 'Councillor')
          check_councillors councillors, 'Morph::Councillor', nil
        end
      end

      describe 'when class name and module name is supplied' do
        it 'should create classes and object instances' do
          Object.const_set 'Ppc', Module.new unless defined? Ppc
          councillors = Morph.from_csv(csv, 'Councillor', Ppc)
          check_councillors councillors, 'Ppc::Councillor', nil
        end
      end

      def csv
  %Q[name,party,councillors,councils,council_experience
Ted Roe,labour,Councillor for Stretford Ward,Trafford Council,
Ali Davidson,labour,,Basildon District Council,
]
      end
    end
  end

  describe "don't mixin private methods" do
    context 'when class defines argument_provided?()' do
      it 'morph method still works' do
        eval "class NoPrivate; def convert_to_morph_method_name(); 'x'; end; include Morph; end"
        morph = NoPrivate.new
        expect(morph.convert_to_morph_method_name).to eq 'x'
        morph.morph 'x', 'y'
        expect(morph.x).to eq 'y'
      end
    end

    context 'when class defineds argument_provided?()' do
      it 'method missing override still works' do
        eval "class NoPrivate; def argument_provided?(); 'x'; end; include Morph; end"
        morph = NoPrivate.new
        expect(morph.argument_provided?).to eq 'x'
        morph.x = 'y'
        expect(morph.x).to eq 'y'
      end
    end
  end

  describe 'mixin ClassMethods' do
    it 'hides @@adding_morph_method @@morph_methods @@morph_attributes' do
      eval 'class Tree; include Morph; end; t = Tree.new; t.this = "that"'
      expect(Tree.const_get(:ClassMethods).class_variables).to eq []
      expect(Tree.class_variables).to eq []
    end
  end

end
