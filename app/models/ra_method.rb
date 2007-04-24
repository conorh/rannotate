class RaMethod < ActiveRecord::Base
  belongs_to :ra_container
  belongs_to :ra_comment 
  belongs_to :file_container, :foreign_key => 'file_id', :class_name => 'RaFile'
  
  def RaMethod.type_string
  	'method'
  end
  
  def container_name
    @attributes['container_name']
  end  

  def container_type
    @attributes['container_type']
  end
  
  # this is a helper method for getting the library that a method is in
  # uses the piggybacked variable if available
  def ra_library   
    if(ra_library_name != nil)
      # when listing methods this helper checks to see if we already have the name of the library
      return RaLibrary.new({:name => ra_library_name})
    else
      return ra_container.ra_library
    end
  end
  
  def container?
  	return false
  end
  
  def RaMethod.find_all_highest_version()
    # TODO: Another find_by_sql that needs to be Active Recordized
	  RaMethod.find_by_sql("SELECT rm.*, rc.full_name AS container_name, rc.type AS container_type, rl.name AS ra_library_name FROM ra_methods AS rm, ra_containers AS rc, ra_libraries AS rl " +
		  "WHERE rm.ra_container_id = rc.id AND rc.ra_library_id = rl.id AND rl.current = 1 " +
		  "ORDER BY rm.name ASC"
	  )
  end
  
  # Get a string with the visibility of this method Public Instance / Private Instance etc.
  def visibility_string(capitalize_words = true)  
    str = RaContainer::VISIBILITY[visibility.to_i]
    if(capitalize_words) then str.capitalize! end
            
    if(capitalize_words)
      singleton ? str += " Class" : str += " Instance"
    else
      singleton ? str += " class" : str += " instance"
    end
    
    return str    
  end
end
