ActionController::Routing::Routes.draw do |map|
  # Add your own custom routes here.
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Here's a sample route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  # map.connect '', :controller => "welcome"

  # default route (id must be a number) 
  map.connect ':controller/:action/:id', :id => /\d+/

	# this route allows for 'static' links to be created to a class/module that still display the sidebar frame
  map.connect 'doc/link/:type/:name', :controller => 'doc', :action => 'index'
  
  # make nice cachable URLs for the sidebar
  map.connect 'doc/sidebar/:type', :controller => 'doc', :action => 'sidebar'
  
  # make nice URLs for doc/classes and /doc/modules
  map.connect 'doc/:action/:name', :controller => 'doc'
  
end
