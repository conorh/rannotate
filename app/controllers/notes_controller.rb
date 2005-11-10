class NotesController < ApplicationController
  cache_sweeper :note_sweeper, :only => [:create]
	
	# Display a list of notes
  def list
    @category = params[:category]
    @name = params[:name]    
    @content_url = params[:return_url]
    
    @notes = Note.find(:all, :conditions => ["category = ? AND name = ?", @category, @name], :order=> "created_at ASC")	
    
    if(params[:no_layout])
      render :layout=>false
    end	
  end
  
  # Show all immediate children of this note. This only works for classes right now. Because...
  # A note is the immediate child of another note if the parent has the format 'somename' and the child the format 'somename.blah'
  # currently only methods have this format
  def overview
    @category = params[:category]
    @name = params[:name]    
    @content_url = params[:return_url]
    
    searchName = @name + Note::METHOD_SEPARATOR + '%';
    @notes = Note.find_by_sql(["SELECT DISTINCT name FROM notes WHERE category = ? AND name LIKE ?", @category, searchName]) 	
  end
  
  # Display a list of notes for the entire site.. up to 30
  def list_new
    @category = params[:category]
    @name = params[:name]    
    @content_url = params[:return_url]
    
		@notes = Note.find(:all, :limit => 50, :order=> "created_at DESC")    	 								
  end

  def new
    @note = Note.new
    @note.category = params[:category]
    @note.name = params[:name]
    @note.content_url = params[:content_url]
  end

  def preview		
    @note = Note.new(params[:note])
    @note.created_at = Time.now
    @note.skip_ban_validation = true
    @note.valid?
		
	if @params['create'] && @note.errors.empty?
      create
	end
  end

  def create  
    @note = Note.new(params[:note])
    @note.ip_address = request.remote_ip;
    @note.skip_ban_validation = local_request?
    if !@note.save
      render :action => 'preview'
    else        
      expire_page(:controller => "doc", :action => 'files', :name => @note.name)
      expire_page(:controller => "doc", :action => 'modules', :name => @note.name)
      expire_page(:controller => "doc", :action => 'classes', :name => @note.name)    
    
    	expire_page :action => "list"
    	render :action => 'success'
    end
  end
	
end