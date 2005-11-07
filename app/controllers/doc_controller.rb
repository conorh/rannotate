class DocController < ApplicationController
	def index
    unless params[:type].nil? and params[:name].nil?
      @start_page = url_for(:action => params[:type], :name => params[:name])
    end
    render :layout => false
	end

  def sidebar 
    type = params[:type]           
        
    # Get what should be displayed in the left sidebar
    case type
      when 'classes'
        @list = RaContainer.find(:all, :conditions => ["type = ? OR type = ?", RaClass.to_s, RaModule.to_s], :order => "full_name ASC")	      
      when 'files'
        @list = RaContainer.find(:all, :conditions => ["type = ?", RaFile.to_s], :order => "full_name ASC")	      
      when 'methods'
        @list = RaMethod.find(:all, :order => "name ASC")		    
      else
        @list = RaContainer.find(:all, :conditions => ["type = ? OR type = ?", RaClass.to_s, RaModule.to_s], :order => "full_name ASC")	
    end    
    
  end

  # Used to display inline notes
  def notes 
    render_notes(params[:category], params[:name], params[:content_url])  		
  end
  
  def source_code
    render_source(params[:method_id])
  end

    # TODO: get the container when we don't know the type, just the full_name
    def container
      # redirect to the correct link
    end

	def files
	  get_container(RaFile)
	  render :action => 'container'
	end
	
	def modules
	  get_container(RaModule)
	  render :action => 'container'	
	end
	
	def classes
	  get_container(RaClass)
	  render :action => 'container'
	end
	
	protected
	
	# Get a container (file,class, module) and everything necessary to display it's documentation
	def get_container(type)
		@container_name = @params[:name]
		@current_url = '/doc/' + type.type_string.pluralize + '?name=' + @container_name		
		
		# Get the container (there can be multiple matches if the container is defined in multiple files)
		@ra_container = RaContainer.find(:first, :include => :ra_comment, :conditions => ["full_name = ? AND type = ?", @container_name, type.to_s])						
								
		# Get all the methods in this container (and join with their comments)
		methods = RaMethod.find(:all, :include => :ra_comment, :conditions => ["ra_container_id = ?", @ra_container.id], :order => "name ASC")
			
		# Divide up the methods into public/protected and class/instance, this array defines the order  
        @ra_methods = {}      
		methods.each do |method|
		    if(method.visibility.to_i == RaContainer::VIS_PRIVATE) then next end
		
    		vis = method.visibility_string
		    unless @ra_methods[vis] then @ra_methods[vis] = [] end
		    @ra_methods[vis].push(method)
		end	
		# setup the order that that the method sections are output
        @ra_visibilities = ['Public Class', 'Public Instance', 'Protected Class', 'Protected Instance', 'Private Class', 'Private Instance']			
						
		# Get all of the other code objects that this container contains
        results = RaCodeObject.find(:all, :conditions => ["ra_container_id = ?", @ra_container.id], :order => "name ASC")
        
        # Divide up the code objects into the various types
        @ra_code_objects = {}
        results.each do |obj| 
          unless @ra_code_objects.has_key?(obj.class) then @ra_code_objects[obj.class] = [] end
          @ra_code_objects[obj.class].push(obj)
        end
       
		# Get the other containers that this container is parent of
		@ra_children = RaContainer.find(:all, :conditions => ["parent_id = ?", @ra_container.id], :order => "full_name ASC")
		
		# Get a list of counts of the different notes
		results = Note.connection.select_all("SELECT name, count(name) AS count FROM notes WHERE name LIKE '" + @container_name + ".%' GROUP BY name");
		@note_count = {}
		for result in results
		  @note_count[result['name']] = result['count']
		end	
		
		count = Note.count(["name = ?", @container_name]);
		@note_count[@container_name] = count
		
	end		
	
    def render_notes(container_type, container_name, current_url)
      render_component(:controller => 'notes', :action=>'list', 
        :params=> {:no_layout => true, :category=>container_type, :name=>container_name, :return_url=>current_url }
      ) 		    
    end	
    
    def render_source(id)
      @source_code = RaSourceCode.find(id).source_code
      render :partial => 'source_code'
    end

end