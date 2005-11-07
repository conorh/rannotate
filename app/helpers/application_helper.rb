# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def sidebar_nav
    return '[' + link_to_unless_current("Files", :controller => "doc", :action => "sidebar", :type => "files") + ']' +
    '[' + link_to_unless_current("Classes", :controller => "doc", :action => "sidebar", :type => "classes") + ']' +
    '[' + link_to_unless_current("Methods", :controller => "doc", :action => "sidebar", :type => "methods") + ']<br/>' + 
    '[' + link_to_unless_current("Search", :controller => "search", :action => "index") + ']'
  end

  def link_to_container(ra_container)
    action = ra_container.class.type_string.pluralize    
    return link_to(ra_container.full_name, 
      {:controller => "doc", :action=> action, :name => ra_container.full_name},
      :target=>'docwin')
  end
  
  def link_to_container_child(child)
    # TODO: instead of linking to the container use a more general action
    # /container . It will do the work of discovering the container type etc.

    action = 'container'    
    return link_to(child.name + " (" + child.parent_name + ")", 
      {:controller => "doc", :action=> action, :name => child.parent_name, 
      :anchor => child.name },
      :target=>'docwin')
  end
  
end
