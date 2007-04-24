class Admin::NotesController < ApplicationController
	before_filter :login_required
	helper :notes
	layout 'admin/admin.rhtml'
			
	def show
  # Start main code
  s = File.open("d:\\rails_site_notes.xml").read
  array = s.scan(/<entry>.*?<title type="text">New note for - ([^<]*)<\/t.*?d>([^<]*)<\/p.*?l">(.*?)<\/summ.*?e>([^<]*)</m)

  array.each do |entry|
  n = Note.new
    
  if(s == "Index page")
    container_name = "index"
    note_type = "index"
    note_group = "index"
  elsif(s =~ /Method/)
    m = s.match(/Method ([a-zA-z0-9_]+) of ([a-zA-z0-9_:]+)/)
    container_name = m[1]
    note_type = "RaMethod"
    note_group = m[0] # method name
  elseif(s =~ / section of /)
    m = s.match(/([a-zA-z0-9_]+) section of ([a-zA-z0-9_:]+)/)
    container_name = m[1]
    type = get_note_type(m[0])
    note_type = type
    note_group = type
  else
    container_name = m
    type = get_container_type(m)
    note_type = type
    note_group = type
  end
  
  n.container_name = container_name
  n.note_type = note_type
  n.note_group = note_group
  n.email = entry[4]
  n.text = entry[3]
  n.ip_address = "127.0.0.1"
  n.created_at = entry[1]
  n.updated_at = entry[1]
  n.total_votes = 0
  n_version = "1.8.4"
  n.status = 0
  
  n.save
  end
  
  puts "done!"	
	end
	
	
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
	
	# show the list of notes waiting for moderation
	def list_moderate
	   @notes = Note.find(:all, :conditions => ["approved = ?", false])
	end
	
	def moderate
	   # get the list of notes to approve
	   # get the list of notes to delete
	   # get the list of notes to hide
	end
   

def get_contanier_type(type_string)
  container = RaContainer.find_by_name(type_string) 
  return container.class.to_s
end

def get_note_type(type_string)
  case type_string
     when "Method" then return "RaMethod"
     when "Children" then return "RaChildren"
     when "InFiles" then return "RaInFile"
     when "Attributes" then return "RaAttribute"
     when "Constants" then return "RaConstant"
     when "Includes" then return "RaInclude"
     when "Requires" then return "RaRequire"
     when "Aliases" then return "RaAlias"    
  end
end

end