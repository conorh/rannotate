class NoteVoting < ActiveRecord::Migration
  def self.up
  
    # this table keeps track of votes for a note and 
    # it prevents people from voting for the same note twice from the same IP
    create_table "votes", :force => true do |t|     
      t.column "type", :string, :limit => 15   
      t.column "ref_id", :integer # the id of the object that this vote refers to
      t.column "ref_string", :string, :limit => 100 # the name of the object that this vote refers to
      t.column "vote_value", :integer      
      t.column "ip_address", :string, :limit => 20
      t.column "created_at", :timestamp
    end
    
    add_column :notes, :total_votes, :integer, :default => 0
                            
  end

  def self.down
     drop_table :votes
     remove_column :notes, :total_votes     
  end
end
