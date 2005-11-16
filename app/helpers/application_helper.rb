# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def sidebar_nav
    return '[' + link_to_unless_current("Files", :controller => "doc", :action => "sidebar", :type => "files") + ']' +
    '[' + link_to_unless_current("Classes", :controller => "doc", :action => "sidebar", :type => "classes") + ']' +
    '[' + link_to_unless_current("Methods", :controller => "doc", :action => "sidebar", :type => "methods") + ']<br/>' + 
    '[' + link_to_unless_current("Search", :controller => "search", :action => "index") + ']'
  end
  
  # Given the name and type of a container (type = method,file, etc..)
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
	
  def link_to_container(ra_container)
    action = ra_container.class.type_string.pluralize
    
    return link_to(ra_container.full_name, 
      {:controller => "doc", :action=> action, :name => ra_container.full_name},
      :target=>'docwin')
  end
  
  def link_to_container_child(child)
    action = child.ra_container.class.type_string.pluralize
    
    return link_to(child.name + " (" + child.ra_container.full_name + ")",     
      {:controller => "doc", :action=> action, :name => child.ra_container.full_name,
       :anchor => child.name },
       :target=>'docwin')
  end
end
