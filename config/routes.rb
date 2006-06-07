ActionController::Routing::Routes.draw do |map|
  # Add your own custom routes here.
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Here's a sample route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # You can have the root of your site routed by hooking up ''
  map.connect '', :controller => "doc"  
  map.connect 'admin/', :controller => "admin/upload"  
  
  # routing rules to give nice URLs to class and modules with version numbers
  map.connect 'class/:name/:version', :controller => 'doc', :action => 'classes', 
    :version => nil, :requirements => {:version => /\d\.\d\.\d/}
  map.connect 'file/:name/:version', :controller => 'doc', :action => 'files',
    :version => nil, :requirements => {:version => /\d\.\d\.\d/}
  map.connect 'module/:name/:version', :controller => 'doc', :action => 'modules', 
    :version => nil, :requirements => {:version => /\d\.\d\.\d/}
  
  # routing ruls to give nice ULRs to class and modules with methods and version numbers
  map.connect 'class/:name/:method/:version', :controller => 'doc', :action => 'classes', :method => nil, :version => nil
  map.connect 'file/:name/:method/:version', :controller => 'doc', :action => 'files', :method => nil, :version => nil
  map.connect 'module/:name/:method/:version', :controller => 'doc', :action => 'modules', :method => nil, :version => nil
  
  # routing rule to match the list types with possible version numbers
  map.connect 'list/:type/:library/:version', :controller => 'doc', :action => 'list', :library => nil, :version => nil
  
  # routing rule to give nice url to history of library links
  map.connect 'history/library/:name', :controller => 'history', :action=> 'library'
  
  # routing rule to give nice URL to history links
  map.connect 'history/:type/:name', :controller => 'doc', :action => 'history'
  
  # routing rule to search for anything that doesn't match the above
  map.connect '/:name', :controller => 'doc', :action => 'search'
  
  # default route (id must be a number) 
  map.connect ':controller/:action/:id', :id => /\d+/
    
end
