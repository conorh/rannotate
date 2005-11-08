class RaMethod < ActiveRecord::Base
  belongs_to :ra_container
  belongs_to :ra_comment 
  
  def RaMethod.type_string
  	"method"
  end
  
  def container?
  	return false
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
