require_relative 'spec_helper'
require 'date'

class User < SentiQL::Base

  set_schema :name, :full_name, :email, :crypted_password, :salt, :created_at, :updated_at
  set_table :users

  #before_save :set_updated_at
  #before_create :set_created_at
  before_save :touch_before_save
  before_create :touch_before_create
  after_create :touch_after_create
  after_save :touch_after_save

  class << self

    def count
      r = self.first "SELECT count(*) AS count FROM #{table}"
      r[:count]
    end

  end

  protected

  #def set_updated_at
    #self[:updated_at] = Time.now
  #end

  #def set_created_at
    #self[:created_at] = Time.now
  #end
  
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

end


describe SentiQL::Base do

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
        u.created_at.should_not be_nil
        sleep(1)
        lambda { u.save }.should_not change(u, :created_at)
      end

      it "updates updated_at attr" do
        u = User.new :name=>'Natalie'
        u.save
        u[:full_name] = 'Natalie Portman'
        lambda { u.save }.should change(u, :updated_at)
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
