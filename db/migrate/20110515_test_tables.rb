class TestTables < ActiveRecord::Migration

  def self.up
    create_table :users do |t|
      t.string :name
      t.string :full_name
      t.string :email
      t.string :crypted_password
      t.string :salt

      t.timestamps
    end

    create_table :clubs do |t|
      t.string :name
      t.text :desc
      t.text :reqs

      t.timestamps
    end
  end

  def self.down
    drop_table :users
    drop_table :clubs
  end

end
