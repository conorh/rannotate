class RaContainer < ActiveRecord::Base
  belongs_to :ra_comment
  belongs_to :ra_library
  has_many :ra_code_object, :dependent => :delete_all

  VIS_PUBLIC = 1
  VIS_PROTECTED = 2  
  VIS_PRIVATE = 3

  # Converts the visibility integer into a string name (ex. 1 -> 'public')  
  VISIBILITY = {VIS_PUBLIC => 'public', VIS_PROTECTED => 'protected', VIS_PRIVATE => 'private'}
  
  def container?
  	true
  end

  def RaContainer.find_all_highest_version(types, library = nil, version = nil)
	sql = "SELECT rc.* FROM ra_containers AS rc, ra_libraries AS rl WHERE type IN (?) AND ra_library_id = rl.id ";
			  
  	if(library != nil && version != nil)	
  		ver_int = RaLibrary.ver_string_to_int(version)
  		sql += " AND rl.name = ? AND rl.version = ? ORDER BY full_name ASC"
  		RaContainer.find_by_sql([sql, types, library, ver_int])
  	elsif(library != nil)
  		sql += " AND rl.name = ? AND rl.current = ? ORDER BY full_name ASC"
  		RaContainer.find_by_sql([sql, types, library, true])
  	else
  		sql += " AND rl.current = ? ORDER BY full_name ASC"  		
   		RaContainer.find_by_sql([sql, types, true])
   	end    			  		
  end
  
  def RaContainer.find_highest_version(full_name, type, library = nil)  
    if(library == nil)  
      result = RaContainer.find_by_sql(["SELECT rc.* FROM ra_containers AS rc, ra_libraries AS rl WHERE " +
        "full_name = ? AND type = ? AND ra_library_id = rl.id AND rl.current = ? ORDER BY full_name ASC", full_name, type, true])
    else
      version = RaLibrary.ver_string_to_int(library)
      result = RaContainer.find_by_sql(["SELECT rc.* FROM ra_containers AS rc, ra_libraries AS rl WHERE " +
        "full_name = ? AND type = ? AND ra_library_id = rl.id AND rl.version = ? ORDER BY full_name ASC", full_name, type, version])    
    end
    
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
