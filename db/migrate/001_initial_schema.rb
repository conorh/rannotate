class InitialSchema < ActiveRecord::Migration
  def self.up  	
    create_table "bans", :force => true do |t|
      t.column "ip_filter", :string, :limit => 16
    end

    create_table "notes", :force => true do |t|
      t.column "category", :string, :limit => 20 
      t.column "name", :string, :limit => 100
      t.column "email", :string, :limit => 60
      t.column "text", :text
      t.column "ip_address", :string, :limit => 16
      t.column "created_at", :timestamp
      t.column "updated_at", :timestamp
    end

    add_index "notes", ["category", "name"], :name => "ind_cat_name"

    create_table "ra_code_objects", :force => true do |t|
      t.column "ra_container_id", :integer
      t.column "type", :string, :limit => 15
      t.column "name", :string, :limit => 128
      t.column "value", :string, :limit => 128
      t.column "visibility", :string, :limit => 1
      t.column "read_write", :string, :limit => 2
      t.column "comment", :text
    end

    create_table "ra_comments", :force => true do |t|
      t.column "comment", :text
    end

    create_table "ra_containers", :force => true do |t|
      t.column "type", :string, :limit => 15
      t.column "parent_id", :integer
      t.column "name", :string
      t.column "full_name", :string
      t.column "superclass", :string
      t.column "ra_comment_id", :integer
      t.column "ra_library_id", :integer
    end

    create_table "ra_in_files", :force => true do |t|
      t.column "file_name", :string
      t.column "ra_container_id", :integer
    end

    create_table "ra_libraries", :force => true do |t|
      t.column "name", :string, :limit => 128
      # this notes whether this row is the most current library version for this library
      # equivalent to SELECT MAX(version) FROM ra_libraries WHERE name = 'blah'
      t.column "current", :boolean
      # this column contains the date that a library was uploaded into the system
      # it can be overidden
      t.column "date", :datetime 
      t.column "version", :integer
      t.column "major", :integer
      t.column "minor", :integer
      t.column "release", :integer
    end

    create_table "ra_methods", :force => true do |t|
      t.column "ra_container_id", :integer
      t.column "name", :string, :limit => 128
      t.column "parameters", :string
      t.column "block_parameters", :string
      t.column "singleton", :boolean
      t.column "visibility", :string, :limit => 1
      t.column "force_documentation", :boolean
      t.column "ra_comment_id", :integer
      t.column "ra_source_code_id", :integer
    end

    create_table "ra_source_codes", :force => true do |t|
      t.column "source_code", :text
    end

    create_table "users", :force => true do |t|
      t.column "login", :string, :limit => 80
      t.column "password", :string, :limit => 40
    end  
  end

  def self.down
  end
end
