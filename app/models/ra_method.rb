class RaMethod < ActiveRecord::Base
  belongs_to :ra_container
  belongs_to :ra_comment 
  
  def RaMethod.type_string
  	"method"
  end
  
  def container_name
    @attributes['container_name']
  end  

  def container_type
    @attributes['container_type']
  end 
  
  def container?
  	return false
  end
  
  def RaMethod.find_all_highest_version()
	RaMethod.find_by_sql("SELECT rm.*, rc.full_name AS container_name, rc.type AS container_type FROM ra_methods AS rm, ra_containers AS rc, ra_libraries AS rl " +
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
