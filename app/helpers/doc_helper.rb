require 'rdoc/markup/simple_markup'
require 'rdoc/markup/simple_markup/to_html'

module DocHelper

    # return the number of notes in a certain category, or 0 if there are none
    def get_count(note_count, category)
      note_count[category] ? note_count[category] : 0
    end

		# markup the source code using the syntax helper
    def markup_source_code(code)
			syntax = Syntax::Convertors::HTML.for_syntax "ruby"
			return syntax.convert(code)    
    end

		# show a link to display the source code for a method
    def show_source_link(id)
      # construct a javascript function that either hides the source div if it's showing already,
      # or gets the source via an Ajax call and shows it
      element = "method_source_#{id}"
      function = "Element.visible('#{element}') ? Element.hide('#{element}') : " +
                  remote_function(
                    :update => 'method_source_' + id.to_s, 
                    :url => { :action => 'source_code', :method_id=>id },
                    :complete => "Element.show('#{element}')")
      
      html = link_to_function("Source", function)
  	  return html
    end

		# show the number of notes in a category for a container and show a link to display the notes
    def show_notes_link(category)
      # in the doc_controller we count up the notes, so output them here
      if(@note_count[category])
        count = @note_count[category].to_i
      else
        count = 0
      end
            
      # construct a javascript function that either hides the notes div if it's showing already,
      # or gets the notes via an Ajax call and shows it
      element = "notes_" + category
      function = "Element.visible('#{element}') ? Element.hide('#{element}') : " +
                  remote_function(
                    :update => 'notes_' + category, 
                    :url => { :action => 'notes', :name=>@container_name, :category=>category, :content_url=> @container_url },
                    :complete => "Element.show('#{element}')")
      
      html = link_to_function(pluralize(count, "note"), function)
  	  return html
    end

		# render the notes for the class
    def render_notes(container_type, container_name, current_url)
      render_component(:controller => 'notes', :action=>'list', 
        :params=> {:no_layout => true, :category=>container_type, :name=>container_name, :return_url=>current_url }
      ) 		    
    end

		# Markup the rdoc comments for display
    def markup(str, remove_para=false)
      return '' unless str
      unless defined? @markup # only define the markup object once
        @markup = SM::SimpleMarkup.new
        
        # TODO: This does not work, previously it depended on us being able to check if something was defined before we would link it
        # here though it is too expensive to do that for each entry as it would involve a DB lookup
        # instead we should do it at the time we are generating the inserts into the DB and place special
        # markers around those things to be hyperlinked
        
        # class names, variable names, file names, or instance variables
        #@markup.add_special(/(
        #                       \b([A-Z]\w*(::\w+)*[.\#]\w+)  #    A::B.meth
        #                      | \b([A-Z]\w+(::\w+)*)       #    A::B..
                       #      | \#\w+[!?=]?                #    #meth_name 
                       #      | \b\w+([_\/\.]+\w+)+[!?=]?  #    meth_name
        #                     )/x, 
        #                    :CROSSREF)

        # external hyperlinks
        @markup.add_special(/((link:|https?:|mailto:|ftp:|www\.)\S+\w)/, :HYPERLINK)

        # and links of the form  <text>[<url>]
        @markup.add_special(/(((\{.*?\})|\b\S+?)\[\S+?\.\S+?\])/, :TIDYLINK)
      end

      unless defined? @html_formatter
        @html_formatter = Hyperlinker.new(self)
      end

      # Convert leading comment markers to spaces, but only if all non-blank lines have them
      if str =~ /^(?>\s*)[^\#]/
        content = str
      else
        content = str.gsub(/^\s*(#+)/)  { $1.tr('#',' ') }
      end

      res = @markup.convert(content, @html_formatter)
      if remove_para
        res.sub!(/^<p>/, '')
        res.sub!(/<\/p>$/, '')
      end
      res
    end  

	# Subclass of the SM::ToHtml class that helps to create hyperlinks out of links
	# in the documentation
	class Hyperlinker < SM::ToHtml

		def initialize(dochelper)
			@dochelper = dochelper
			super()
		end

		# We're invoked when any text matches the CROSSREF pattern
	  # (defined in MarkUp). If we fine the corresponding reference,
  	# generate a hyperlink.
  	def handle_special_CROSSREF(special)
    	name = special.text
    	if name[0,1] == '#'
      	name = name[1..-1]
      end

  	  if /([A-Z].*)[.\#](.*)/ =~ name
	      ref = @dochelper.link_to(name, {:controller => 'doc', :action => 'search', :name => $1}, :target=>'sidebar')
	    else
  	    ref = @dochelper.link_to(name, {:controller => 'doc', :action => 'search', :name => name}, :target=>'sidebar')
	    end

			ref
	  end

		# And we're invoked with a potential external hyperlink mailto:
	  # just gets inserted. http: links are checked to see if they
	  # reference an image. If so, that image gets inserted using an
	  # <img> tag. Otherwise a conventional <a href> is used.  We also
	  # support a special type of hyperlink, link:, which is a reference
	  # to a local file whose path is relative to the --op directory.
	  def handle_special_HYPERLINK(special)
	    url = special.text
	    gen_url(url, url)
	  end

	  # Here's a hypedlink where the label is different to the URL
	  #  <label>[url]       
	  def handle_special_TIDYLINK(special)
  	  text = special.text
      unless text =~ /\{(.*?)\}\[(.*?)\]/ or text =~ /(\S+)\[(.*?)\]/ 
        return text
      end
      label = $1
      url   = $2
      gen_url(url, label)
    end

    # Generate a hyperlink for url, labeled with text. Handle the
    # special cases for img: and link: described under handle_special_HYPEDLINK
    def gen_url(url, text)
      if url =~ /([A-Za-z]+):(.*)/
        type = $1
        path = $2
      else
        type = "http"
        path = url
        url  = "http://#{url}"
      end

      if type == "link"
        if path[0,1] == '#'     # is this meaningful?
          url = path
        else
          url = path
        end
      end

      if (type == "http" || type == "link") && 
      	url =~ /\.(gif|png|jpg|jpeg|bmp)$/
      	"<img src=\"#{url}\">"
      else
        "<a href=\"#{url}\" target=\"_blank\">#{text.sub(%r{^#{type}:/*}, '')}</a>"
      end
    end

  end # end of HyperlinkHtml class

end # end of DocHelper module