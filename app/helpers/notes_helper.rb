module NotesHelper

	require 'syntax/convertors/html'

	# Remove the parent class/module name from a method name (ex. Something.blah -> blah)
	def strip_parent(name)
		index = name.rindex(Note::METHOD_SEPARATOR)
		if(index != nil)
			return name.slice(index+1..name.length)
		end
		
		return name
	end
	
	# Mangle the input email address to hide it from email address harvesters
	def mangle_email_for_display(email)
		newEmail = String.new(email)
		newEmail.gsub!(/@/, " AT ")
		newEmail.gsub!(/\./," . ")	
		return h(newEmail)
	end
	
	def get_return_url(note)
	  container_type = note.get_container().class.to_s
      container = RaContainer.type_to_route(container_type)
      container_params = {:controller => 'doc', :action => container, :container => note.container_name, :anchor => 'note_' + note.id.to_s}
      code_obj_params = {:controller => 'doc', :action => 'container', :type => container_type, :container => note.container_name}
      
      case note.note_type
	    when RaModule.to_s then return url_for(container_params)
	    when RaClass.to_s then return url_for(container_params)
	    when RaFile.to_s then return url_for(container_params)   	    
	    when RaMethod.to_s then return url_for(container_params.merge({:method => note.note_group}))
	    when RaInFile.to_s then return url_for(code_obj_params.merge({:anchor => 'note_' + note.id.to_s, :expand => 'infiles'})) 
	    when RaAttribute.to_s then return url_for(code_obj_params.merge({:anchor => 'note_' + note.id.to_s, :expand => 'attributes'}))
	    when RaConstant.to_s then return url_for(code_obj_params.merge({:anchor => 'note_' + note.id.to_s, :expand => 'constants'})) 
	    when RaInclude.to_s then return url_for(code_obj_params.merge({:anchor => 'note_' + note.id.to_s, :expand => 'includes'})) 
	    when RaRequire.to_s then return url_for(code_obj_params.merge({:anchor => 'note_' + note.id.to_s, :expand => 'requires'})) 
	    when RaAlias.to_s then return url_for(code_obj_params.merge({:anchor => 'note_' + note.id.to_s, :expand => 'aliases'}))
	    when "RaChildren" then return url_for(code_obj_params.merge({:anchor => 'note_' + note.id.to_s, :expand => 'children'}))
        when "index" then return url_for(:controller => 'doc', :action => "index", :anchor => 'note_' + note.id.to_s)
      end
      
      return url_for(:controller => 'doc', :action => "index")	 	  	
	end
	
	# Syntax highlight the input
	# Transform line breaks into HTML
	# If summary input parameter is set then limit text to 40 characters and replace newlines with spaces
	def fix_note_for_display(note, summary = nil)
		text = String.new(note)
		
		if(summary != nil && summary == "1")			
			text = text.slice!(0..100)
			text.gsub!(/(\r\n|\n|\r)/, " ")
			
			if(note.length > 100)
				text += " ... "
			end
		end
				
		# Kill all HTML elements
		text.gsub!(/</,"&lt;")
		text.gsub!(/>/,"&gt;")		
		
		# To prevent the ruby code from being mangled by the rest of the text substitutions
		# we save it in an instance variable and then re-add it later
		@rubycode = []		
		text.gsub!(/<ruby>(.*?)<\/ruby>/m ) { @rubycode.push($1); "!CODE_EXTRACT!" }										
	
		# Take care of newlines
		text.gsub!(/(\r\n|\n|\r)/, "\n") # lets make them newlines crossplatform
		text.gsub!(/\n\n+/, "\n\n") # zap dupes
		text.gsub!(/([^\n])(\n)([^\n])/, '\1\2<br/>\3') # turn single newline into <br />		
		text.gsub!(/\n\n/, "<br/><br/>\n") # turn two newlines into paragraph
		
		# Extract anything between <ruby></ruby> tags and syntax highlight it
		syntax = Syntax::Convertors::HTML.for_syntax "ruby"
				
		# Now place back in the ruby code that we extracted
		@rubycode.reverse!()
		text.gsub!(/!CODE_EXTRACT!/) { syntax.convert(@rubycode.pop()) }

		# auto link any links	 
		text = auto_link(text, :all, :rel => "nofollow", :target=> "_blank")
		return text
	end

end
