class DocController < ApplicationController

  # cache the main controllers for this class  
  caches_page :files, :modules, :classes, :sidebar

  # display the index page with an optional home page
  def index
  	# if a class/name is specified then set that for the main frame link  
    unless params[:type].nil? and params[:name].nil?
      @start_page = url_for(:action => params[:type], :name => params[:name])
    end
    
    # if no main page is specified then look for a home page to display (id == 1)  
   	unless @start_page.nil?
    	main_page = RaFile.find(:first, :conditions=>['id=1'])
    	unless main_page.nil?
      	@start_page = url_for(:action => 'files', :name => main_page.full_name)
      end
    end
  end

  # display a file
  def files
    get_container(RaFile)
    render :action => 'container'
  end
  
  # display a module
  def modules
    get_container(RaModule)
    render :action => 'container' 
  end
  
  # display a class
  def classes
    get_container(RaClass)
    render :action => 'container'
  end
  
  # display a list of entries
  def list
  	get_list(params[:type])
  end
  
  # Used by AJAX to display inline notes
  def notes 
    render_notes(params[:category], params[:name], params[:content_url])      
  end
  
  # Used by AJAX to display inline source code
  def source_code
    render_source(params[:method_id])
  end  
  
  # search the database for classes, methods, files
  def search
  	@search_text = params[:name]
  	get_search_results(@search_text)
  end    
  
  ### START protected methods
  protected  
  
  # get a list of entries to display for the left sidevar
  def get_list(type = 'classes')   	  
    # Get what should be displayed in the left sidebar
    case type
      when 'classes'
       	@list = RaContainer.find(:all, :conditions => ["type = ? OR type = ?", RaClass.to_s, RaModule.to_s], :order => "full_name ASC")
      when 'files'
        @list = RaContainer.find(:all, :conditions => ["type = ?", RaFile.to_s], :order => "full_name ASC")       
      when 'methods'
        @list = RaMethod.find(:all, :include => :ra_container, :order => "ra_methods.name ASC")
      else
        @list = RaContainer.find(:all, :conditions => ["type = ? OR type = ?", RaClass.to_s, RaModule.to_s], :order => "full_name ASC") 
    end            	
  end
  
  # Get a container (file,class, module) and everything necessary to display it's documentation
  def get_container(type)
    @container_name = @params[:name]
    
    # Get the container
    @ra_container = RaContainer.find(:first, :include => :ra_comment, :conditions => ["full_name = ? AND type = ?", @container_name, type.to_s])            
                
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
    @ra_in_files = RaInFile.find(:all, :conditions => ["container_id = ?", @ra_container.id])
    
    # Get a list of counts of the different categories of notes for this container
    # TODO: make this more active recordish
    results = Note.connection.select_all("SELECT category, count(name) AS count FROM notes WHERE name = '" + @container_name + "' GROUP BY category");
    @note_count = {}
    for result in results
      @note_count[result['category']] = result['count']
    end
                     
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
      	
    name = '%' + params[:name].downcase + '%'    
    
    temp = RaContainer.find(:all, :limit => 100, :conditions => ["lower(full_name) like ? AND type IN ('RaModule', 'RaClass')", name], :order => 'full_name ASC')        
    temp.push(RaMethod.find(:all, :limit => 100, 
    	:conditions => ["lower(ram.name) like ? AND ram.ra_container_id = rc.id", name], 
    	:joins => 'ram, ra_containers rc',
    	:select => 'ram.*, rc.full_name AS container_name, rc.type AS container_type',
    	:order => 'ram.name ASC'
    	)
    )
    temp.push(RaCodeObject.find(:all,
    	:limit => 100, 
    	:conditions => ["lower(rco.name) like ? AND rco.type IN('RaConstant', 'RaMethod', 'RaAttribute') AND rco.ra_container_id = rc.id", name],
    	:joins => 'rco, ra_containers rc',
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
  def render_notes(container_type, container_name, current_url)
    render_component(:controller => 'notes', :action => 'list', 
      :params=> {:no_layout => true, :category=>container_type, :name=>container_name, :return_url=>current_url }
    )         
  end 
  
  # Render the source inline
  def render_source(id)
    @source_code = RaSourceCode.find(id).source_code
    render :partial => 'partials/source_code'
  end

end