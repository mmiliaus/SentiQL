require_relative 'spec_helper'
require 'date'
require 'active_support/all'

class Club < SentiQL::Base

  set_table :clubs
  set_schema :name, :description, :reqs, :created_at, :updated_at

  def validate
    name_not_blank?
    description_not_blank? && description_not_longer_then(400)
  end

  def name_not_blank?
    if self[:name].blank?
      errors << "Name can't be blank" 
      return false
    end
    return true
  end

  def description_not_blank?
    if self[:description].blank?
      errors << "Description can't be blank"
      return false
    end
    return true
  end

  def description_not_longer_then max
    if self[:description].length > max
      errors << "Description can't be longer then #{max.to_s}"
      return false
    end
    return true
  end

end

class User < SentiQL::Base

  set_schema :name, :full_name, :email, :crypted_password, :salt, :created_at, :updated_at
  set_table :users

  before_save :touch_before_save
  before_create :touch_before_create
  after_create :touch_after_create
  after_save :touch_after_save
  before_validation :touch_before_validation
  after_validation :touch_after_validation

  def validate
    name_not_blank?
  end

  def name_not_blank?
    if self[:name].blank?
      errors << "Name can't be blank" 
      return false
    end
    return true
  end

  class << self

    def count
      r = self.first "SELECT count(*) AS count FROM #{table}"
      r[:count]
    end

  end

  protected
  
  def touch_before_save
    self[:before_save_touched] = Time.now
  end

  def touch_before_create
    self[:before_create_touched] = Time.now
  end

  def touch_after_create
    self[:after_create_touched] = Time.now
  end

  def touch_after_save
    self[:after_save_touched] = Time.now
  end

  def touch_before_validation
    self[:before_validation_touched] = Time.now
  end

  def touch_after_validation
    self[:after_validation_touched] = Time.now
  end

end


describe SentiQL::Base do

  describe 'validations' do

    describe '.valid?' do

      it 'returns false if there are errors' do
        c = Club.new :name=>'Fight Club'
        c.save
        c.valid?.should be_false
        c[:description] = 'some description'
        c.valid?.should be_true
      end

    end

    it "doesn't save to DB if record is not valid" do
      c = Club.new :name=>'Fight Club'
      c.save
      c[:id].should be_nil
    end

    it "saves record if its valid" do
      c = Club.new :name=>'Fight Club'
      c.save
      c[:description] = 'some description'
      c.save
      c.id.should_not be_nil
    end

    it "returns a list of errors if records does not pass validations"  do
      c = Club.new :name=>'Fight Club'
      c.valid?
      c.errors.size.should_not == []
    end

  end

  describe User do

    describe '.create' do
      it 'creates a new record in DB' do
        lambda { User.create :name=>'Natalie' }.should change(User, :count).by(1)
      end

      it 'returns and instance of User' do
        u = User.create :name=>'Natalie'
        u.should be_an_instance_of(User)
      end

      it 'sets :id of record in DB to an instance' do
        u = User.create :name=>'Natalie'
        u[:id].should_not be_nil
      end
    end

    describe '.updated_all' do

      it "updates model attrs" do
        u = User.create :name=>'Natalie'
        u.update_attributes({:full_name=>'Natalie Portman', :email=>'natalie@portman.com'})
        u.save
        uu = User.find_by :id=>u.id
        uu.full_name.should == 'Natalie Portman'
        uu.email.should == 'natalie@portman.com'
      end
      
      it "ignores :id in new attributes hash" do
        u = User.create :name=>'Natalie'
        lambda { u.update_attributes({:id=>'1111', :full_name=>'Natalie Portman', :email=>'natalie@portman.com'}) }.should_not change(u, :id)
      end

    end

    describe '.save' do
      it "creates new record if instance is new" do
        u = User.new :name=>'Natalie'
        lambda{ u.save }.should change(User, :count).by(1)
      end
      
      it "updates existing record if instance was already created" do
        u = User.new :name=>'Natalie'
        u.save
        u[:full_name] = 'Natalie Portman'
        lambda { u.save }.should_not change(User, :count)
      end

      it "sets created_at attr" do
        u = User.new :name=>'Natalie'
        u.save
        uu = User.find_by :id=>u.id
        uu.created_at.should_not be_nil
        sleep(1)
        lambda { u.save }.should_not change(u, :created_at)
      end

      it "updates updated_at attr" do
        u = User.new :name=>'Natalie'
        u.save
        uu = User.find_by :id=>u.id
        uu.updated_at.should_not be_nil
        uu[:full_name] = 'Natalie Portman'
        lambda { uu.save }.should change(uu, :updated_at)
      end

    end

    describe 'filters' do

      before do
      end

      it "executes before_save every time instance is saved" do
        u = User.new :name=>'Natalie'
        u.save
        sleep(1)
        lambda { u.save }.should change(u, :before_save_touched)
      end

      it "executes before_create filters only when record is created" do
        u = User.new :name=>'Natalie'
        u.save
        sleep(1)
        lambda { u.save }.should_not change(u, :before_create_touched)
      end

      it "executes before_validation filters even if record is not valid" do
        u = User.new :before_validation_touched=>Time.now
        lambda { u.save }.should change(u, :before_validation_touched)
      end

      it "executes after_validation filters after record only if record validates" do
        u = User.new :after_validation_touched=>Time.now
        sleep(1)
        lambda { u.save }.should_not change(u, :after_validation_touched)
        u[:name] = 'Natalie'
        sleep(1)
        lambda { u.save }.should change(u, :after_validation_touched)
      end
      
      it "executes after_create filters only after record is created" do
        u = User.new :name=>'Natalie'
        u.save
        lambda { u.save }.should_not change(u, :after_create_touched)
      end

      it "executes after_save filters after everytime instance is saved" do
        u = User.new :name=>'Natalie'
        u.save
        lambda { u.save }.should change(u, :after_save_touched)
      end

    end
  end  

  describe '.first' do
    it 'returns nil when no records found' do
      r = SentiQL::Base.first 'SHOW TABLES LIKE ?', ['non_existing_tbl%']
      r.should == nil
    end

    it 'returns a hash if record found with keys representing column values' do
      r = SentiQL::Base.first 'SELECT CONCAT(?,?) AS str', ['a','b']
      r.should be_an_instance_of(Hash)
      r[:str].should == 'ab'
    end
  end

  describe '.all' do
    it 'returns Mysql2::Result which holds data in Hashes' do
      r = SentiQL::Base.all 'SHOW OPEN TABLES'
      r.should be_an_instance_of(Mysql2::Result)
      r.first.should be_an_instance_of(Hash)
    end
  end


end
