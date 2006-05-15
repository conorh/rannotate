class DocController < ApplicationController

  # cache the main actions for this controller
  caches_page :list, :files, :modules, :classes

  # display the index page with an optional home page
  def index
    # if no main page is specified then look for a home page to display (id == 1)  
    main_page = RaFile.find_by_id(0)
    if(main_page != nil)              
      @home = main_page
    end
  end

  # display a file
  def files
  	if(params[:method])
  	  	method(RaFile.to_s)
	    render :action => 'method'   	  	
  	else  
	    get_container(RaFile.to_s) 
	    render :action => 'container'       
	end
  end

  # display a module
  def modules
  	if(params[:method])
  	  	method(RaModule.to_s)
	    render :action => 'method'   	  	  	
  	else
  		get_container(RaModule.to_s)
    	render :action => 'container'     	
    end
  end
  
  # display a class  
  def classes    
  	if(params[:method])
  	  	method(RaClass.to_s)
	    render :action => 'method'   	  	  	
  	else	    	
	  	get_container(RaClass.to_s)
	    render :action => 'container'     	
	end
  end

  # display a method  
  def method(type)
  	@container_name = @params[:name]
  	@version = @params[:version]
    @ra_container = RaContainer.find_highest_version(@container_name, type, @version)
    @method = RaMethod.find(:first, :include => :ra_comment, :conditions => ["ra_container_id = ? AND name = ?", @ra_container.id, @params[:method]])  	
    @source_code = RaSourceCode.find(@method.ra_source_code_id).source_code
  end
  
  # display a list of entries
  def list
  	get_list(params[:type], params[:library], params[:version])
  end 
  
  # Used by AJAX to display inline notes
  def notes 
    render_notes(params[:container_name], params[:note_group])      
  end   
  
  # Used by AJAX to display inline source code
  def source_code
    render_source(params[:source_id])
  end  
  
  # search the database for classes, methods, files
  def search
  	@search_text = params[:name]
  	get_search_results(@search_text)
  end
  
  # list all of the libraries in the system  
  def libraries
  	all_libs = RaLibrary.find(:all, :order => "name ASC, version DESC")
  	
  	# collect all of the libraries into a hash by library name, each
  	# entry in the hash contains a list of all the library versions
  	@libraries = Hash.new
  	all_libs.each do |l|
  		unless @libraries[l.name] then @libraries[l.name] = Array.new end
  		@libraries[l.name].push(l)
  	end  	  	
  end  
  
  # Display the history for a container
  def history
    get_container(@params[:type])
  end
  
  ###########################
  ### START protected methods
  ###########################
  protected  
  
  # get a list of entries to display for the left sidevar
  def get_list(type = 'classes', library = nil, version = nil)
    # Get what should be displayed in the left sidebar
    case type
      when 'files'
        @list = RaContainer.find_all_highest_version([RaFile.to_s], library, version)           
      when 'methods'
        @list = RaMethod.find_all_highest_version()
      else
       	@list = RaContainer.find_all_highest_version([RaClass.to_s, RaModule.to_s], library, version)
    end
    @version = version
    @library = library
    @type = type
    
    if(type == 'files')
      render :action => 'list_files'
    end
  end
  
  # Get a container (file,class, module) and everything necessary to display it's documentation
  def get_container(cont_type)
    @container_name = @params[:name]
    @version = @params[:version] # this can be nil if the most recent version is requested
    @expand = @params[:expand]
    @ra_container = RaContainer.find_highest_version(@container_name, cont_type, @version)    
    unless(@ra_container)
    	@error = "Could not find: " + @container_name
    	return
    end
                
    # Get all the methods in this container (and join with their comments)
    methods = RaMethod.find(:all, :include => :ra_comment, :conditions => ["ra_container_id = ?", @ra_container.id], :order => "name ASC")
      
    # Divide up the methods into public/protected and class/instance
	@ra_methods = {}      
    methods.each do |method|
        # Don't display private methods
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
    
    # Get the list of the files that this container is defined in
    @ra_in_files = RaInFile.find(:all, :conditions => ["ra_container_id = ?", @ra_container.id])
    
    # Get a list of counts of the different categories of notes for this container
    # TODO: make this more active recordish
    results = Note.connection.select_all("SELECT note_group, count(container_name) AS count FROM notes WHERE container_name = '" + @container_name + "' GROUP BY note_group");
    @note_count = {}
    for result in results
      @note_count[result['note_group']] = result['count']
    end

    @container_type = @ra_container.class.type_string                         
    @container_url = url_for(:action => @ra_container.class.type_string.pluralize, :name => @container_name)                      
  end       
  
  # execute a search and return the results
  # results are put in the @search_results class variable and @result_count contains the total result count
  # if something goes wrong then the class variable @error contains the error message
  def get_search_results(search_text)
  	@search_results = Hash.new
  	
  	if(search_text == nil || search_text.length < 3)
    	@search_results = {}
    	@error = "Search too short. Must be longer than 2 characters."
	    return
  	end
    
    # what type to include in output, and what order to display them in
    @display = [RaModule, RaClass, RaMethod, RaConstant, RaAttribute]
      	
    name = '%' + search_text + '%'    
    
    temp = RaContainer.find(:all, :limit => 100, 
    	:conditions => ["lower(rc.full_name) like ? AND rc.type IN ('RaModule', 'RaClass') AND rl.id = rc.ra_library_id AND rl.current = ?", name, true], 
    	:select => 'rc.*',
    	:joins => "rc, ra_libraries AS rl",
    	:order => 'rc.full_name ASC'
    )
    
    temp.push(RaMethod.find(:all, :limit => 100, 
    	:conditions => ["lower(ram.name) like ? AND ram.ra_container_id = rc.id AND rc.ra_library_id = rl.id AND rl.current = ?", name, true], 
    	:joins => 'ram, ra_containers AS rc, ra_libraries AS rl',
    	:select => 'ram.*, rc.full_name AS container_name, rc.type AS container_type',
    	:order => 'ram.name ASC'
    	)
    )
    temp.push(RaCodeObject.find(:all, :limit => 100, 
    	:conditions => ["lower(rco.name) like ? AND rco.type IN('RaConstant', 'RaMethod', 'RaAttribute') AND rco.ra_container_id = rc.id AND rc.ra_library_id = rl.id AND rl.current = ?", name, true],
    	:joins => 'rco, ra_containers AS rc, ra_libraries AS rl',
    	:select => 'rco.*, rc.full_name AS container_name, rc.type AS container_type',
    	:order => 'rco.name ASC'
    	)
    )
        
    temp.flatten!
    # Create a hash of the results
    temp.each do |obj| 
      unless @search_results.has_key?(obj.class) then @search_results[obj.class] = [] end
      @search_results[obj.class].push(obj)
    end 
    @results_count = temp.length 	
  end
  
  # Render the notes inline
  def render_notes(container_name, note_group)
    render_component(:controller => 'notes', :action => 'list', 
      :params=> {:no_layout => true, :container_name=>container_name, :note_group=>note_group }
    )         
  end 
  
  # Render the source inline
  def render_source(id)
    @source_code = RaSourceCode.find(id).source_code
    render :partial => 'doc/partials/source_code'
  end

end