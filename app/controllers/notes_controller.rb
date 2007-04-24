class NotesController < ApplicationController
    
  cache_sweeper :note_sweeper, :only => [:preview]
  caches_page :list_new
	
  # Display a list of notes
  def list
    @container_name = params[:container_name]
    @note_group = params[:note_group]
    
    @notes = Note.find(:all, :conditions => ["container_name = ? AND note_group = ?", @container_name, @note_group], :order=> "created_at ASC")	
    
    if(params[:no_layout])
      render :layout=>false
    end
  end 
  
  # Display a list of notes for the entire site.. up to 20
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
    
    @hide_vote = true
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
      send_note_edit_email(@note)      
      render :action => 'success'
    end
  end
  
  # Send an email
  def send_note_edit_email
    
  end
  
  # Save a vote for a note and then show the success page if it was a success
  def vote
    ip = request.remote_ip;
    note_id = params[:id]
    vote_value = params[:value].to_i
            
    @note = Note.find_by_id(note_id) 
    
    if(@note == nil)
      @error = "Could not find note, sorry!"
      return
    end
    
    existing_vote = NoteVote.find(:first, :conditions => ["ref_id = ? AND ip_address = ?", note_id, ip])
    if(existing_vote != nil)
      @error = "Sorry your IP has already voted for this note"
      return
    end 
    
    if(vote_value == NoteVote::USEFUL)
      @note.total_votes += 1
    elsif(vote_value == NoteVote::NOT_USEFUL || vote_value == NoteVote::SPAM)
      @note.total_votes -= 1
    end
    @note.save
    
    # now that we have updated a note we have to expire all the pages it appears on from the cache
    NoteSweeper.expire_cache(self, @note)    

    # save a record of this vote
    @vote = NoteVote.new()
    @vote.vote_value = vote_value
    @vote.ip_address = ip
    @vote.ref_id = note_id
    @vote.save
  end

  # show a rankings page for highest ranked notes and most notes (and more in the future)
  def rankings
    # TODO: It seems to me that there should be a more active recordish way of doing this?
    @most_notes = Note.find_by_sql("SELECT *, COUNT(*) AS note_count FROM notes GROUP BY container_name ORDER BY note_count DESC LIMIT 10")
    @highest_notes = Note.find(:all, :limit => 10, :order => "total_votes DESC") 
    render :layout => 'doc'
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
   
   # helper method used by get_note_params
   def get_container_params(id, type_string)	
	     type = RaContainer.find(id)
	     return {:container_name => type.full_name,
	       :note_group => type_string, :note_type => type_string,
	       :version => type.ra_library.ver_string }	
   end
   
   # helper method used by get_note_params   
   def get_method_params(id, type_string)
	     type = RaMethod.find(id)
	     return {:container_name => type.ra_container.full_name,
	       :note_group => type.name, :note_type => type_string,
	       :version => type.ra_container.ra_library.ver_string }  
   end
   
   # helper method used by get_note_params   
   def get_codeobj_params(id, type_string)
         type = RaContainer.find(id)
	     return {:container_name => type.full_name,
	       :note_group => type_string, :note_type => type_string,
	       :version => type.ra_library.ver_string}      
   end

   def get_index_params()
	     return {:container_name => "index",
	       :note_group => "index", :note_type => "index",
	       :version => "n/a"}  	      
   end 
	
end