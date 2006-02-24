ActionController::Routing::Routes.draw do |map|
  # Add your own custom routes here.
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Here's a sample route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  map.connect '', :controller => "doc"  
  map.connect 'admin/', :controller => "admin/upload"  
  
  map.connect 'class/:name/:method', :controller => 'doc', :action => 'classes', :method => nil
  map.connect 'file/:name/:method', :controller => 'doc', :action => 'files', :method => nil
  map.connect 'module/:name/:method', :controller => 'doc', :action => 'modules', :method => nil
  
  map.connect '/:name', :controller => 'doc', :action => 'search'
  
  # default route (id must be a number) 
  map.connect ':controller/:action/:id', :id => /\d+/
    
end
