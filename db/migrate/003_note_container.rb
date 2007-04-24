class NoteContainer < ActiveRecord::Migration
  def self.up
    
    # Removing the container_id from the note        
    
    # remove_column :notes, :ra_container_id                              
  end

  def self.down 
    # Removing the container_id from the note
    # add_column :notes, :ra_container_id
  end
end
