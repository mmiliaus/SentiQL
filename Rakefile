require 'bundler'
require 'yaml'
require 'logger'
require 'active_record'

Bundler::GemHelper.install_tasks


MIGRATIONS_DIR = 'db/migrate'
APP_PATH = File.join(File.dirname(__FILE__))

namespace :db do

  task :environment do
    ENV['RACK_ENV'] ||= 'development'
    @config = YAML.load_file('config/database.yml')[ENV['RACK_ENV']]
    ActiveRecord::Base.establish_connection @config
  end

  desc 'Migrate the database (options: VERSION=x, VERBOSE=false).'
  task :migrate => :environment do
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate MIGRATIONS_DIR, ENV['VERSION'] ? ENV['VERSION'].to_i : nil
  end

  desc 'Rolls the schema back to the previous version (specify steps w/ STEP=n).'
  task :rollback => :configure_connection do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    ActiveRecord::Migrator.rollback MIGRATIONS_DIR, step
  end

  desc "Retrieves the current schema version number"
  task :version => :configure_connection do
    puts "Current version: #{ActiveRecord::Migrator.current_version}"
  end

  namespace :test do

    desc "Creates testing database by cloning main database"
    task :load do
      @config = YAML.load_file('config/database.yml')['test']
      ActiveRecord::Base.establish_connection @config
      tables = ActiveRecord::Base.connection.select_all("SHOW TABLES").map { |m| m.values.first }
      tables.each do |table_name|
        ActiveRecord::Base::connection.execute("DROP TABLE #{table_name}")
      end
      ActiveRecord::Migration.verbose = true
      ActiveRecord::Migrator.migrate MIGRATIONS_DIR
    end
  end

end
