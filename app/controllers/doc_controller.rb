class DocController < ApplicationController

  # turn off sessions to speed things up
  session :off

  # cache the main actions for this controller
  caches_page :index, :container, :library, :list, :libraries, :history, :file_contents
  
  # TODO: Document why the notes helper is needed here?
  helper :notes

  # display the index page with an optional home page
  def index    
    if(RANNOTATE_HOME_PAGE != nil)
      main_page = RaContainer.find_highest_version(RANNOTATE_HOME_PAGE, 'RaFile')      
      if(main_page != nil)         
        @home = main_page
      end
    end
  end
  
  # display a container given a library name, class/file/module name, method name, version
  def container
    lib_name = params[:lib_name]
    container_name = params[:container]
    version = params[:version]
    method = params[:method]
    
    # Depending on what parameters we are given we either display
    # the method page, the class/module file page, or the library home page    
    if(method)
      method(lib_name, container_name, version, method)
	    render :action => 'method'
    elsif(container_name)
      get_container(lib_name, container_name, version)
    else
      get_library(lib_name, version)
     render :action => 'library'
    end
  end 
  
  # display a list of classes/files/methods
  def list
  	get_list(params[:lib_name], params[:type], params[:version])
  	@type = params[:type]
  	
  	# if there is no library name then this is a list of all the entries in the system
  	# so we have to show the library name beside each
  	if(params[:lib_name] == nil)
	    @show_library = true  	
  	end
  	
  	# files are listed in a single column, so they have a separate template
  	if(params[:type] == 'files')
  	  render :action => 'list_files'
  	end  	
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
  	@libraries = RaLibrary.find(:all, :order => "name ASC", :group => "name")  	
  end
  
  # Display the history for a container
  def history
    get_container(@params[:type])
  end
  
  # show which files contain which parts of a class
  def file_contents
    name = @params[:container]
    type = @params[:type]
    
    # get the container
    @ra_container = RaContainer.find_by_full_name(name)
          
    # get all of the code objects and methods that have this container as a parent
    code_obj = RaCodeObject.find(:all, :conditions => ["ra_container_id = ?", @ra_container.id], :order => "name ASC")    
    
    # Get all the methods in this container
    code_obj += RaMethod.find(:all, :conditions => ["ra_container_id = ? AND visibility = ?", @ra_container.id, RaContainer::VIS_PUBLIC], :order => "name ASC")
       
    # Get the other containers that this container is parent of
    code_obj += RaContainer.find(:all, :conditions => ["parent_id = ?", @ra_container.id], :order => "full_name ASC")
           
    # group everything by file
    @file_contents = {}
        
    for obj in code_obj
      unless @file_contents.has_key?(obj.file_id)
        @file_contents[obj.file_id] = {:obj => RaFile.find_by_id(obj.file_id)}
      end
      
      unless @file_contents[obj.file_id].has_key?(obj.class) then @file_contents[obj.file_id][obj.class] = [] end
      @file_contents[obj.file_id][obj.class].push(obj)
    end
    
    type = @ra_container.class.type_string
    @container_url = url_for(:action => type.pluralize, :container => @ra_container.full_name)      
  end
  
  ###########################
  ### START protected methods
  ###########################
  protected  
 
  # display the home page for a library
  def get_library(lib_name, version)
    @library = RaLibrary.find_by_name(lib_name)
    get_list(lib_name, params[:type], version)
    
    # if the library has a main_container_id set then use the description from
    # that container for the home page, otherwise use one of the shorter descriptions
    if(@library.main_container_id)
      main = RaContainer.find_by_id(@library.main_container_id)
      @description = main.ra_comment.comment
    elsif(@library.long_description)
      @description = @library.long_description
    elsif(@library.short_description)
      @description = @library.short_description
    end
  end 
 
  # display a method
  def method(lib_name, container_name, version, method)
    @ra_container = RaContainer.find_highest_version(container_name, version)
    @method = RaMethod.find(:first, :include => :ra_comment, :conditions => ["ra_container_id = ? AND name = ?", @ra_container.id, method])
    @source_code = RaSourceCode.find(@method.ra_source_code_id).source_code
    @page_title = RANNOTATE_SITE_NAME + " " + @ra_container.full_name + "-" + @method.name
    @container_url = "" # get_doc_url(lib_name, container_name, version, method)
  end 
  
  # get a list of entries to display for the list pages
  def get_list(library, type = 'classes', version = nil)
    case type
      when 'files'      
        @list = RaContainer.find_all_highest_version([RaFile.to_s], library, version)      
      when 'methods'
        @list = RaMethod.find_all_highest_version()
      else
       	@list = RaContainer.find_all_highest_version([RaClass.to_s, RaModule.to_s], library, version)
    end    
  end
  
  # Get a container (file,class, module) and everything necessary to display it's documentation
  def get_container(lib_name, container_name, version)
    @container_name = container_name
    @library = lib_name
    @version = version # this can be nil if the most recent version is requested
    @expand = @params[:expand]
    @ra_container = RaContainer.find_highest_version(@container_name, lib_name, @version)
    unless(@ra_container)
    	@error = "Could not find: " + @container_name
    	return
    end
    
    @page_title = RANNOTATE_SITE_NAME + " " + @container_name      
                
    # Get all the methods in this container (and join with their comments)
    methods = RaMethod.find(:all, :include => [:ra_comment, :file_container], :conditions => ["ra_container_id = ?", @ra_container.id], :order => "ra_methods.name ASC")
      
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
    # join with the file_id so that we can display the files the code objects were defined in
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
    @container_url = "" # get_doc_url(lib_name, container_name, version, method)            
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
    @display = [RaModule, RaClass, RaMethod, RaConstant, RaAttribute, RaFile]
    
    if(params[:exact] == nil)
      name = '%' + search_text.downcase + '%'
    else
      name = search_text.downcase
    end
    
    temp = RaContainer.find(:all, :limit => 100, 
    	:conditions => ["LOWER(rc.full_name) LIKE ? AND rl.id = rc.ra_library_id AND rl.current = ?", name, true],
    	:select => 'rc.*',
    	:joins => "rc, ra_libraries AS rl",
    	:order => 'rc.full_name ASC'
    )
    
    temp.push(RaMethod.find(:all, :limit => 100,
    	:conditions => ["LOWER(ram.name) LIKE ? AND ram.ra_container_id = rc.id AND rc.ra_library_id = rl.id AND rl.current = ?", name, true],
    	:joins => 'ram, ra_containers AS rc, ra_libraries AS rl',
    	:select => 'ram.*, rc.full_name AS container_name, rc.type AS container_type',
    	:order => 'ram.name ASC'
    	)
    )
    temp.push(RaCodeObject.find(:all, :limit => 100,
    	:conditions => ["LOWER(rco.name) LIKE ? AND rco.type IN('RaConstant', 'RaMethod', 'RaAttribute') AND rco.ra_container_id = rc.id AND rc.ra_library_id = rl.id AND rl.current = ?", name, true],
    	:joins => 'rco, ra_containers AS rc, ra_libraries AS rl',
    	:select => 'rco.*, rc.full_name AS container_name, rc.type AS container_type',
    	:order => 'rco.name ASC'
    	)
    )
        
    temp.flatten!
        
    # Check to see if there is only one result, it is a container and we are only looking for an exact result
    # if so then redirect to that container        
    if(temp.length == 1)
      obj = temp[0]
      if(params[:exact] && obj.container?)    
        redirect_to :action => obj.class.type_string.pluralize, :name => obj.full_name, :method => nil
      end
    end
    
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