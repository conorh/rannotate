class ValueForCodeObjectsAsText < ActiveRecord::Migration
  # change the size of the ra_code_objects column so that it cannot overflow
  def self.up
    change_column "ra_code_objects", "value", :text, :limit => 256
  end

  def self.down
    change_column "ra_code_objects", "value", :string, :limit => 128
  end
end