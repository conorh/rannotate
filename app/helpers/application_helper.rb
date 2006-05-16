# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

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
  
  # Given the name and type of a container (type = class,file, etc..)
  # link to that type
  def link_to_container_by_name(type, name)      
    link_params = {:controller => "doc", :action=> type.pluralize, :name => name}
    if(@version)
      link_params[:version] = @version
    end    
    return link_to(name, link_params)
  end
  
  # This method looks at the type of the object and creates a link to the correct page
  # to display that object. ex. if the object is RaMethod then it will link to the parent
  # class
	def link_to_doc(object)
		object.container? ? link_to_container(object) : link_to_container_child(object)
	end
	
  # If this is a container type object (class, method, file) then link to it directly
  def link_to_container(ra_container, max_length = 300)
    action = ra_container.class.type_string.pluralize
    
    link_params = {:controller => "doc", :action => action, :name => ra_container.full_name }
    if(@version)
      link_params[:version] = @version
    end
    
    link_name = ra_container.full_name
    if(link_name.length > max_length)
      link_name = link_name[0,max_length] + ".."
    end
    
    return link_to(link_name, link_params)
  end
  
  # If this is a child of a container object (method, constant etc.) then link to it's container
  def link_to_container_child(child)    
   	container_name = child.container_name
    container_type = child.container_type
    
    # If we haven't done a database join to pre-retrieve these values then we get them here
    # this could involve another DB query if no join with the container table has been done
    if(container_name == nil || container_type == nil)
    	container_type = child.ra_container.class.to_s
    	container_name = child.ra_container.full_name
    end
   
    link_params = {:controller => "doc", :action => RaContainer.type_to_route(container_type), :name => container_name, :anchor => child.name }
    if(@version)
      link_params[:version] = @version
    end
    
    return link_to(child.name + " (" + container_name + ")", link_params)
       
  end
  
  def link_to_method(method_name, container_type)
    link_params = {:action => container_type.pluralize, :method => method_name}
    if(@version)
      link_params[:version] = @version
    end    
    link_to(method_name, link_params)  
  end
  
  # get the current library version
  def get_current_version()
    return RaLibrary.find(:first, :conditions => ["current = ?", true])
  end
  
end
