# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  # Given the name and type of a container (type = class,file, etc..)
  # link to that type
  def link_to_container_by_name(type, name)
    return link_to(name, 
      {:controller => "doc", :action=> type.pluralize, :name => name},
      :target=>'docwin')		
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
      {:controller => "doc", :action => action, :name => ra_container.full_name},
      :target=>'docwin')
  end
  
  # If this is a child of a container object (method, constant etc.) then link to it's container
  def link_to_container_child(child)
    action = child.ra_container.class.type_string.pluralize
    
    return link_to(child.name + " (" + child.ra_container.full_name + ")",     
      {:controller => "doc", :action=> action, :name => child.ra_container.full_name,
       :anchor => child.name },
       :target=>'docwin')
  end
end
