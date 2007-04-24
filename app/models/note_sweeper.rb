class NoteSweeper < ActionController::Caching::Sweeper
  observe Note
  
  def after_save(note)
    expire_cache(note)
  end
  
  def after_destroy(note)
    expire_cache(note)
  end

private
  
  # TODO: Expire the following
  # :index, :container, :library, :list, :libraries
  
  def expire_cache(note)
       container = RaContainer.type_to_route(note.ra_container.class.to_s)      
      
      if(note.note_type == "index")
        page_params = {:controller => 'doc', :action => "index"}
        expire_page(page_params)  
      elsif(note.note_type == "RaMethod")
        page_params = {:controller => 'doc', :action => container, :name => note.container_name }      
        
        # Expire the container page
        expire_page(page_params)
        
        # expire the container with version page
        versioned = page_params.merge({:version => note.version})
        expire_page(versioned)
        
        # Expire the method page
        method = page_params.merge({:method => note.note_group})
        expire_page(method)
        
        # Expire the method with version page
        method_versioned = method.merge({:version => note.note_group})
        expire_page(method_versioned)        
      else   
         page_params = {:controller => 'doc', :action => container, :name => note.container_name }           
         # expire the container page
         expire_page(page_params)
             
         # expire the container with version page
         versioned = page_params.merge({:version => note.version})
         expire_page(versioned)       
      end
      
      # expire the RSS page
      expire_page(:controller => 'notes', :action => 'rss')

      # expire the newest notes page
      expire_page(:controller => 'notes', :action => 'list_new')  
  end
  
  
end