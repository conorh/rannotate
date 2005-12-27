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
    RaContainer.find_by_sql(["SELECT rc.* FROM ra_containers AS rc, ra_libraries AS rl WHERE " +
      "type IN (?) AND ra_library_id = rl.id AND rl.current = ? ORDER BY full_name ASC", types, true])	
  end
  
  def RaContainer.find_highest_version(full_name, type, library = nil)
    result = RaContainer.find_by_sql(["SELECT rc.* FROM ra_containers AS rc, ra_libraries AS rl WHERE " +
      "full_name = ? AND type = ? AND ra_library_id = rl.id AND rl.current = ? ORDER BY full_name ASC", full_name, type, true])
    if(result)
    	return result[0]
    end  
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
