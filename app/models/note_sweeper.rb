# TODO: this sweeper is not working.. url_for is not working inside the expire_page method
# TODO: so I added the expire code directly inside the notes controller
class NoteSweeper < ActionController::Caching::Sweeper
#  observe Note
  
  def after_save(note)
    expire_cache(note)
  end
  
  def after_destroy(note)
    expire_cache(note)
  end

   # TODO: This should really be a sweeper, but it is not working inside my sweeper
   def self.expire_cache(controller, note)
      container = RaContainer.type_to_route(note.ra_container.class.to_s)      
      
      if(note.note_type == "index")
        page_params = {:controller => 'doc', :action => "index"}
        controller.expire_page(page_params)        
      elsif(note.note_type == "RaMethod")
        page_params = {:controller => 'doc', :action => container, :name => note.container_name }      
        
        # Expire the container page
        controller.expire_page(page_params)
        
        # expire the container with version page
        versioned = page_params.merge({:version => note.version})
        controller.expire_page(versioned)
        
        # Expire the method page
        method = page_params.merge({:method => note.note_group})
        controller.expire_page(method)
        
        # Expire the method with version page
        method_versioned = method.merge({:version => note.note_group})
        controller.expire_page(method_versioned)        
      else   
         page_params = {:controller => 'doc', :action => container, :name => note.container_name }           
         # expire the container page
         controller.expire_page(page_params)
             
         # expire the container with version page
         versioned = page_params.merge({:version => note.version})
         controller.expire_page(versioned)       
      end
      
      # expire the RSS page
      controller.expire_page(:controller => 'notes', :action => 'rss')

      # expire the newest notes page
      controller.expire_page(:controller => 'notes', :action => 'list_new')                
  end

private
  
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
  end
  
  
end