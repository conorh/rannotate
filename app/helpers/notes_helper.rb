module NotesHelper

	require 'syntax'
	require 'syntax/convertors/html'	

	# Remove the parent class/module name from a method name (ex. Something.blah -> blah)
	def strip_parent(name)
		index = name.rindex(Note::METHOD_SEPARATOR)
		if(index != nil)
			return name.slice(index+1..name.length)
		end
		
		return name
	end

	# Display errors in a nicely formatted box
	def display_errors_for(object_name, options = {})
		options = options.symbolize_keys
		object = instance_variable_get("@#{object_name}")
	
		unless object.errors.empty?
			content_tag("div",			
				content_tag("p", "There were problems with the following fields:") +
				content_tag("ul", object.errors.full_messages.collect { |msg| content_tag("li", msg) }),
					"id" => options[:id] || "errorExplanation", "class" => options[:class] || "errorExplanation"
			)
		end		
	end
	
	# Mangle the input email address to hide it from email address harvesters
	def mangle_email_for_display(email)
		newEmail = String.new(email)
		newEmail.gsub!(/@/, " AT ")
		newEmail.gsub!(/\./," . ")	
		return h(newEmail)
	end
	
	# Syntax highlight the input
	# Transform line breaks into HTML
	#	If summary input parameter is set then limit text to 40 characters and replace newlines with spaces
	def fix_note_for_display(note, summary = nil)
		text = String.new(note)
		
		if(summary != nil && summary == "1")			
			text = text.slice!(0..100)
			text.gsub!(/(\r\n|\n|\r)/, " ")
			
			if(note.length > 100)
				text += " ... "
			end
		end
			
		# Extract anything between <ruby></ruby> tags and syntax highlight it
		syntax = Syntax::Convertors::HTML.for_syntax "ruby"
		
		# To prevent the ruby code from being mangled by the rest of the text substitutions
		# we save it in an instance variable and then re-add it later
		@rubycode = []
		text.gsub!(/<ruby>(.*?)<\/ruby>/m ) { @rubycode.push($1); "!CODE_EXTRACT!" }					
					
		# Kill all HTML elements
		text.gsub!(/</,"&lt;")
		text.gsub!(/>/,"&gt;")		
	
		# Take care of newlines
		text.gsub!(/(\r\n|\n|\r)/, "\n") # lets make them newlines crossplatform
		text.gsub!(/\n\n+/, "\n\n") # zap dupes
		text.gsub!(/([^\n])(\n)([^\n])/, '\1\2<br/>\3') # turn single newline into <br />		
		text.gsub!(/\n\n/, "<br/><br/>\n") # turn two newlines into paragraph
		
		# Now place back in the ruby code that we extracted
		text.gsub!(/!CODE_EXTRACT!/) { syntax.convert(@rubycode.pop()) }

		# auto link any links	
		text = auto_link(text, :all, :rel => "nofollow", :target=> "_blank")
		return text
	end

end
