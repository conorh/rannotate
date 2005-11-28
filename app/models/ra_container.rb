class RaContainer < ActiveRecord::Base
  belongs_to :ra_comment

  VIS_PUBLIC = 1
  VIS_PROTECTED = 2  
  VIS_PRIVATE = 3

  # Converts the visibility integer into a string name (ex. 1 -> 'public')  
  VISIBILITY = {VIS_PUBLIC => 'public', VIS_PROTECTED => 'protected', VIS_PRIVATE => 'private'}
  
  def container?
  	true
  end
  
  def RaContainer.type_to_route(type)
		case type
			when 'RaFile' 
				return 'files'
			when 'RaClass'
				return 'classes'
			when 'RaModule'
				return 'modules'
			else
				return 'unknown'
		end					
  end
  
end
