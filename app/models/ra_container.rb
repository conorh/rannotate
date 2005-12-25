class RaContainer < ActiveRecord::Base
  belongs_to :ra_comment
  belongs_to :ra_library

  VIS_PUBLIC = 1
  VIS_PROTECTED = 2  
  VIS_PRIVATE = 3

  # Converts the visibility integer into a string name (ex. 1 -> 'public')  
  VISIBILITY = {VIS_PUBLIC => 'public', VIS_PROTECTED => 'protected', VIS_PRIVATE => 'private'}
  
  def container?
  	true
  end

  def RaContainer.find_all_highest_version(types, library = nil)
    RaContainer.find(:all, :joins => ",ra_libraries AS rl",
    	:conditions => ["type IN (?) AND ra_library_id = rl.id AND rl.current = ?", types, true],
    	:order => "full_name ASC"    	
    )  	
  end
  
  def RaContainer.find_highest_version(full_name, type, library = nil)
    RaContainer.find(:first, :joins => ",ra_libraries AS rl",
    	:conditions => ["full_name = ? AND type = ? AND ra_library_id = rl.id AND rl.current = ?", full_name, type, true]
    )  	
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
