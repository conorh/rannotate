# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  # Given the name and type of a container (type = class,file, etc..)
  # link to that type
  def link_to_container_by_name(type, name)
    return link_to(name, 
      {:controller => "doc", :action=> type.pluralize, :name => name})		
	end
  
  # This method looks at the type of the object and creates a link to the correct page
  # to display that object. ex. if the object is RaMethod then it will link to the parent
  # class
	def link_to_doc(object)
		object.container? ? link_to_container(object) : link_to_container_child(object)
	end
	
	# If this is a container type object (class, method, file) then link to it directly
  def link_to_container(ra_container)
    action = ra_container.class.type_string.pluralize
    
    return link_to(ra_container.full_name, 
      {:controller => "doc", :action => action, :name => ra_container.full_name})
  end
  
  # If this is a child of a container object (method, constant etc.) then link to it's container
  def link_to_container_child(child)    
   	container_name = child.container_name
    container_type = child.container_type
    
    # If we haven't done a database join to pre-retrieve these values then we get them here
    # this could involve another DB query if no join with the container table has been done
    if(container_name == nil || container_type == nil)
    	container_type = child.ra_container.class.to_s
    	container_name = child.ra_container.full_name
    end
    
    return link_to(child.name + " (" + child.ra_container.full_name + ")",     
      { :controller => "doc", :action => RaContainer.type_to_route(container_type), :name => container_name, :anchor => child.name }
      )
       
  end
end
