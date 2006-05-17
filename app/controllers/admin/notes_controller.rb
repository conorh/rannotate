class Admin::NotesController < ApplicationController
	before_filter :login_required
	helper :notes
	layout 'admin/admin.rhtml'
	
	def index
	  @note_filter = NoteFilter.new(@params['note_filter'])

      if(@request.post?)
        case(@params['form_action'])
		  when 'Run Query'
			if(show_filtered_results())
			  return
			end
		  when 'Delete Selected'
			delete_entries
			if(show_filtered_results())
			  return
			end
          end
	   end
		
       @notes = []
	end
	
	def edit
	  @note = Note.find(@params['id'])
	end
	
	def show
      @note = Note.find(@params['id'])		
	end
	
	# update a note and expire the cache if necessary
	def update
      @note = Note.find(@params[:id])
      @note.skip_ban_validation = true
            
      if @note.update_attributes(@params[:note])
        NoteSweeper.expire_cache(self, @note)       
        flash[:notice] = 'Note was successfully updated.'       
        redirect_to :action => 'show', :id => @params[:id]
      else
        render :action => 'edit'
      end
	end
	
	private
	
	def show_filtered_results
	  if(@params['note_filter'])
		@notes = Note.find_with_filter(@params['note_filter'])
		return true			
	  end	
	  return false
	end	
		
	# delete a bunch of notes expiring the cache as we go
	def delete_entries
      notes = Note.find(@params['ids_for_delete'])
      for note in notes
         NoteSweeper.expire_cache(self, note)      
         Note.delete(note.id)    
      end
	end	

private
   

end