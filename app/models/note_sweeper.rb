# TODO: this sweeper is not working.. url_for is not working inside the expire_page method
# TODO: so I added the expire code directly inside the notes controller
class NoteSweeper < ActionController::Caching::Sweeper
  observe Note
  
  def after_create(note)
    expire_cache(note.container_name)
  end
  
  def after_update(note)
    expire_cache(note.container_name)
  end
  
  def after_destroy(note)
    expire_cache(note.container_name)
  end

private

  # expire any pages in the cache that hold these notes
  def expire_cache(name)    
    expire_page(:controller => "doc", :action => 'files', :name => name)
    expire_page(:controller => "doc", :action => 'modules', :name => name)
    expire_page(:controller => "doc", :action => 'classes', :name => name)
  end
end