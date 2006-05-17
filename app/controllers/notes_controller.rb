class NotesController < ApplicationController
    
  # cache_sweeper :note_sweeper, :only => [:create]
  caches_page :rss, :list_new
	
  # Display a list of notes
  def list
    @container_name = params[:container_name]
    @note_group = params[:note_group]
    
    @notes = Note.find(:all, :conditions => ["container_name = ? AND note_group = ?", @container_name, @note_group], :order=> "created_at ASC")	
    
    if(params[:no_layout])
      render :layout=>false
    end
  end 
  
  # Display a list of notes for the entire site.. up to 30
  def list_new    
    @notes = Note.find(:all, :limit => 20, :order=> "created_at DESC")						
  end
  
  # Generate an RSS feed of the 20 newest notes
  def rss
    @notes = Note.find(:all, :limit => 20, :order=> "created_at DESC")  
    render :layout =>  false    
  end  
  
  # Create a note
  def new
    @note = Note.new(get_note_params(params[:id], params[:type]))
    @note.ref_id = params[:id]
    @note.ref_type = params[:type]
  end
  
  # Preview a note
  def preview
    note_params = get_note_params(params[:note][:ref_id], params[:note][:ref_type])
    
    @note = Note.new(note_params.merge(params[:note]))
    @note.created_at = Time.now
    @note.skip_ban_validation = true
    @note.valid?
		
	if @params['create'] && @note.errors.empty?
      create
	end
  end

  # Save the note to the DB
  def create  
    note_params = get_note_params(params[:note][:ref_id], params[:note][:ref_type])
    
    @note = Note.new(note_params.merge(params[:note]))
    @note.ip_address = request.remote_ip;
    if !@note.save
      render :action => 'preview'
    else
      NoteSweeper.expire_cache(self, @note)            
      render :action => 'success'
    end
  end 
  
private

   # Given the id and type of the object that this note is being attached to
   # get the necessary information to create the note
   def get_note_params(id, type_string)
     case type_string
	   when "RaChildren" then return get_codeobj_params(id, type_string)	     
	   when RaModule.to_s then return get_container_params(id, type_string)
	   when RaClass.to_s then return get_container_params(id, type_string) 
	   when RaFile.to_s then return get_container_params(id, type_string)	                 
	   when RaMethod.to_s then return get_method_params(id, type_string)
	   when RaInFile.to_s then return get_codeobj_params(id, type_string)
	   when RaAttribute.to_s then return get_codeobj_params(id, type_string)
	   when RaConstant.to_s then return get_codeobj_params(id, type_string)
	   when RaInclude.to_s then return get_codeobj_params(id, type_string)
	   when RaRequire.to_s then return get_codeobj_params(id, type_string)
	   when RaAlias.to_s then return get_codeobj_params(id, type_string)
	   when "index" then return get_index_params()
      end

      return {}
   end

   def get_container_params(id, type_string)	
	     type = RaContainer.find(id)
	     return {:container_name => type.full_name, :ra_container_id => type.id, 
	       :note_group => type_string, :note_type => type_string,
	       :version => type.ra_library.ver_string }	
   end
   
   def get_method_params(id, type_string)
	     type = RaMethod.find(id)
	     return {:container_name => type.ra_container.full_name, :ra_container_id => type.ra_container.id,
	       :note_group => type.name, :note_type => type_string,
	       :version => type.ra_container.ra_library.ver_string }  
   end
   
   def get_codeobj_params(id, type_string)
         type = RaContainer.find(id)
	     return {:container_name => type.full_name, :ra_container_id => id,
	       :note_group => type_string, :note_type => type_string,
	       :version => type.ra_library.ver_string}      
   end

   def get_index_params()
	     return {:container_name => "index", :ra_container_id => "0",
	       :note_group => "index", :note_type => "index",
	       :version => "n/a"}  	      
   end 
	
end