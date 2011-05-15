require 'database_cleaner'
require 'yaml'
require 'rspec'
require 'active_record'
require 'mysql2'

require 'sentiql'

ROOT_PATH = File.dirname(__FILE__)


@config = YAML.load_file(File.join(ROOT_PATH, '..', "config/database.yml"))['test']

DB = Mysql2::Client.new( 
      :host=>@config["host"], 
      :username=>@config["username"], 
      :password=>@config["password"], 
      :database=>@config["database"]
    )
DB.query_options.merge!(:symbolize_keys=>true)
SentiQL::Base.connection = DB

ActiveRecord::Base.establish_connection @config

RSpec.configure do |config|

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

end
