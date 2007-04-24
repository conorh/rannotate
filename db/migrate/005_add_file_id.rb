class AddFileId < ActiveRecord::Migration
  def self.up
    add_column :ra_containers, :file_id, :integer                          
    add_column :ra_methods, :file_id, :integer    
  end

  def self.down 
    drop_column :ra_containers, :file_id
    drop_column :ra_methods, :file_id
  end
end
