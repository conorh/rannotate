class RaInFile < ActiveRecord::Base

  belongs_to :ra_container

  def RaInFile.type_string
    return 'infile'
  end

end
