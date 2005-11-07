require 'rdoc/markup/simple_markup'
require 'rdoc/markup/simple_markup/to_html'

module DocHelper

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

    def show_notes_link(name, category)
      full_name = @container_name + Note::METHOD_SEPARATOR + name
      if(@note_count[full_name])
        count = @note_count[full_name].to_i
      else
        count = 0
      end
      
      # construct a javascript function that either hides the notes div if it's showing already,
      # or gets the notes via an Ajax call and shows it
      element = "notes_#{name}"
      function = "Element.visible('#{element}') ? Element.hide('#{element}') : " +
                  remote_function(
                    :update => 'notes_' + name, 
                    :url => { :action => 'notes', :name=>full_name, :category=>category, :content_url=>@current_url },
                    :complete => "Element.show('#{element}')")
      
      html = link_to_function(pluralize(count, "note"), function)
  	  return html
    end

    def render_notes(container_type, container_name, current_url)
      render_component(:controller => 'notes', :action=>'list', 
        :params=> {:no_layout => true, :category=>container_type, :name=>container_name, :return_url=>current_url }
      ) 		    
    end

    def markup(str, remove_para=false)
      return '' unless str
      #unless defined? @markup
        @markup = SM::SimpleMarkup.new

        # class names, variable names, file names, or instance variables
        #@markup.add_special(/(
        #                       \b([A-Z]\w*(::\w+)*[.\#]\w+)  #    A::B.meth
        #                     | \b([A-Z]\w+(::\w+)*)       #    A::B..
        #                     | \#\w+[!?=]?                #    #meth_name 
        #                     | \b\w+([_\/\.]+\w+)+[!?=]?  #    meth_name
        #                     )/x, 
        #                    :CROSSREF)

        # external hyperlinks
        # @markup.add_special(/((link:|https?:|mailto:|ftp:|www\.)\S+\w)/, :HYPERLINK)

        # and links of the form  <text>[<url>]
        # @markup.add_special(/(((\{.*?\})|\b\S+?)\[\S+?\.\S+?\])/, :TIDYLINK)
        ## @markup.add_special(/\b(\S+?\[\S+?\.\S+?\])/, :TIDYLINK)

      #end
      #unless defined? @html_formatter
        @html_formatter = SM::ToHtml.new
      #end

      # Convert leading comment markers to spaces, but only
      # if all non-blank lines have them

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
end
