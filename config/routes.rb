ActionController::Routing::Routes.draw do |map|
  # Add your own custom routes here.
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Route / to /doc/index
  map.connect '', :controller => "doc"
    
  # routing urls for container/library browsing
  map.connect 'lib/:lib_name/:container/:method', :controller => 'doc', :action => 'container',
    :container => nil, :method => nil
    
  # routing urls for container/library browsing
  map.connect 'lib/:lib_name/:version/:container/:method', :controller => 'doc', :action => 'container',
    :name => nil, :method => nil, :requirements => {:version => /\d\.\d\.\d/}
  
  # route to list all classes/files/methods for a library
  map.connect 'lib/:lib_name/list/:type', :controller => 'doc', :action => 'list'
  
  # routing rule to give nice url to history links for both libraries and for classes/modules in that library
  map.connect 'lib/:lib_name/:name/history', :controller => 'doc', :action=> 'history', :name => nil
  
  # route to list all classes/files/methods in the system
  map.connect 'list/:type/:version', :controller => 'doc', :action => 'list'
  
  # Route to the admin portion of the site
  map.connect 'admin/', :controller => 'admin/upload'  
  
  # default route (id must be a number) 
  map.connect ':controller/:action/:id'
  
  # routing rule to search for anything that doesn't match the above
  map.connect '/:name', :controller => 'doc', :action => 'search'
end