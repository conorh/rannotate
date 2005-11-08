# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def sidebar_nav
    return '[' + link_to_unless_current("Files", :controller => "doc", :action => "sidebar", :type => "files") + ']' +
    '[' + link_to_unless_current("Classes", :controller => "doc", :action => "sidebar", :type => "classes") + ']' +
    '[' + link_to_unless_current("Methods", :controller => "doc", :action => "sidebar", :type => "methods") + ']<br/>' + 
    '[' + link_to_unless_current("Search", :controller => "search", :action => "index") + ']'
  end
	
	def link_to_doc_page(object)
		object.container? ? link_to_container(object) : link_to_container_child(object)
	end
	
  def link_to_container(ra_container)
    action = ra_container.class.type_string.pluralize
    
    return link_to(ra_container.full_name, 
      {:controller => "doc", :action=> action, :name => ra_container.full_name},
      :target=>'docwin')
  end
  
  def link_to_container_by_name(name)
    return link_to(name, 
      {:controller => "doc", :action=> 'container', :name => name},
      :target=>'docwin')  
  end
  
  def link_to_container_child(child)
    return link_to(child.name + " (" + child.parent_name + ")", 
      {:controller => "doc", :action=> 'container', :name => child.parent_name, 
       :parent_id => child.ra_container_id, :anchor => child.name },
       :target=>'docwin')
  end
  
end
