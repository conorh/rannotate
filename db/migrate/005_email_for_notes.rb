class EmailForNotes < ActiveRecord::Migration

  def self.up
    # we were missing the call seq from the RDoc code object tree
    # this meant that C implemented methods had parameters like (...) instead 
    # of showing the possible parameters
    add_column :ra_methods, :call_seq, :string
  
    # each note gets an random value used for edit links and a status (approved, edited, etc.)
    add_column :notes, :random_val, :string, :limit => 20
    add_column :notes, :status, :integer, :default => 0

    # keep track of the file that a container/code_object/method is defined in)
    add_column :ra_containers, :file_id, :integer  
    add_column :ra_code_objects, :file_id, :integer
    add_column :ra_methods, :file_id, :integer
    
    # each library gets a short description field
    add_column :ra_libraries, :short_description, :string, :limit => 256
    add_column :ra_libraries, :long_description, :text
    
    # each library can have a 'home_page' which is a particular class/file/module
    add_column :ra_libraries, :main_container_id, :integer
    
    # The value of code objects was too short, make it longer
    change_column :ra_code_objects, :value, :string, :limit => 256
  end

  def self.down
    remove_column :notes, :random_val
    remove_column :notes, :status
                
    remove_column :ra_code_objects, :file_id
    remove_column :ra_methods, :file_id
    remove_column :ra_containers, :file_id
    
    remove_column :ra_libraries, :short_description
    remove_column :ra_libraries, :long_description
    remove_column :ra_libraries, :main_container_id
    
    change_column :ra_code_objects, :value, :string, :limit => 128
  end
end