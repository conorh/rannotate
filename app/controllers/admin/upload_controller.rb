require 'pp'

class Admin::UploadController < ApplicationController
	before_filter :login_required
	layout 'admin/admin.rhtml'

	def index		
	end
	
	# show a list of all libraries in the system
	def list
	   all_libs = RaLibrary.find(:all, :order => "name ASC, version DESC")
  	
      #collect all of the libraries into a hash by library name, each
  	  # entry in the hash contains a list of all the library versions
  	  @libraries = Hash.new
  	  all_libs.each do |l|
  		  unless @libraries[l.name] then @libraries[l.name] = Array.new end
  		  @libraries[l.name].push(l)
  	  end
	end
	
	# delete libraries and all of their associated contents
	def delete	    
		library_ids = @params[:id]
				
		library_ids.each do |library_id, checked|
		  if(checked != "1")
		    next
		  end
		  
		  library = RaLibrary.find(library_id)
		  name = library.name
		 
		  # ok this really should be more activerecord'ish
		  # but I didn't have enough time to do that, so for now we know it works on
		  # two DBs, mysql and postgres
		  begin
		    RaCodeObject.connection.delete("DELETE ra_code_objects FROM ra_code_objects, ra_containers WHERE ra_code_objects.ra_container_id = ra_containers.id AND ra_containers.ra_library_id = " + library_id)
		    RaInFile.connection.delete("DELETE ra_in_files FROM ra_in_files, ra_containers WHERE ra_in_files.ra_container_id = ra_containers.id AND ra_containers.ra_library_id = " + library_id)
		    RaSourceCode.connection.delete("DELETE ra_source_codes FROM ra_source_codes, ra_methods, ra_containers WHERE ra_source_codes.id = ra_methods.ra_source_code_id AND ra_methods.ra_container_id = ra_containers.id AND ra_containers.ra_library_id = " + library_id)
		    RaComment.connection.delete("DELETE ra_comments FROM ra_comments, ra_methods, ra_containers WHERE ra_comments.id = ra_methods.ra_comment_id AND ra_methods.ra_container_id = ra_containers.id AND ra_containers.ra_library_id = " + library_id)
		    RaMethod.connection.delete("DELETE ra_methods FROM ra_methods, ra_containers WHERE ra_methods.ra_container_id = ra_containers.id AND ra_containers.ra_library_id = " + library_id)
		    RaComment.connection.delete("DELETE ra_comments FROM ra_comments, ra_containers WHERE ra_comments.id = ra_containers.ra_comment_id AND ra_containers.ra_library_id =" + library_id)
		    RaContainer.connection.delete("DELETE FROM ra_containers WHERE ra_library_id = " + library_id)
		    RaLibrary.connection.delete("DELETE FROM ra_libraries WHERE id =" + library_id)	
      rescue
		    RaCodeObject.connection.delete("DELETE FROM ra_code_objects WHERE id IN (SELECT ra.id FROM ra_code_objects AS ra, ra_containers AS rc, ra_libraries AS rl WHERE ra.ra_container_id = rc.id AND rc.ra_library_id = rl.id AND rl.id =" + library_id + ")")
		    RaInFile.connection.delete("DELETE FROM ra_in_files WHERE id in (SELECT ra.id FROM ra_in_files AS ra, ra_containers AS rc, ra_libraries AS rl WHERE ra.ra_container_id = rc.id AND rc.ra_library_id = rl.id AND rl.id =" + library_id + ")")
		    RaSourceCode.connection.delete("DELETE FROM ra_source_codes WHERE id IN (SELECT rs.id FROM ra_source_codes AS rs, ra_methods AS rm, ra_containers AS rc, ra_libraries AS rl WHERE rs.id = rm.ra_source_code_id AND rm.ra_container_id = rc.id AND rc.ra_library_id = rl.id AND rl.id =" + library_id + ")")
		    RaComment.connection.delete("DELETE FROM ra_comments WHERE id IN (SELECT rs.id FROM ra_comments AS rs, ra_methods AS rm, ra_containers AS rc, ra_libraries AS rl WHERE rs.id = rm.ra_comment_id AND rm.ra_container_id = rc.id AND rc.ra_library_id = rl.id AND rl.id =" + library_id + ")")
		    RaMethod.connection.delete("DELETE FROM ra_methods WHERE id IN (SELECT ra.id FROM ra_methods AS ra, ra_containers AS rc, ra_libraries AS rl WHERE ra.ra_container_id = rc.id AND rc.ra_library_id = rl.id AND rl.id =" + library_id + ")")
		    RaComment.connection.delete("DELETE FROM ra_comments WHERE id IN (SELECT rs.id FROM ra_comments AS rs, ra_containers AS rc, ra_libraries AS rl WHERE rs.id = rc.ra_comment_id AND rc.ra_library_id = rl.id AND rl.id =" + library_id + ")")
		    RaContainer.connection.delete("DELETE FROM ra_containers WHERE id IN (SELECT rc.id FROM ra_containers AS rc, ra_libraries AS rl WHERE rc.ra_library_id = rl.id AND rl.id =" + library_id + ")")
		  end
		  
		  # make sure that the highest library version is still marked as the current version
		  libraries = RaLibrary.find(:all, :conditions => ["name = ?", name])		  
      max_lib = nil
      max_ver = 0
		  libraries.each do |lib|
		    if(lib.version > max_ver)
		      max_lib = lib
		    end
		    lib.current = false
		    lib.save
		  end	
		  
		  if(max_lib != nil)
		    max_lib.current = true
		    max_lib.save
		  end	  		  		  
		end	
		
		redirect_to :action => :list
	end
	
  # given a directory import all files from that directory
	def mass_import
	  dir = params[:directory]
	  files = Dir.glob(dir + "/*.out")
	  
	  @success = []
	  @total_count = 0
	  
	  for file in files
	    do_import(file)
	    if(@error)
	      if(params[:ignore])
	        @success << "failed: " + file + " " + @error
	        next
	      else
	        @success << "failed: " + file + " " + @error
	        break
	      end
	    end
      @success << "success: " + file	    
	  end
	  
    render :action => :create			  
	end
	
	# import a single file
	def import
	  @total_count = 0	
	  do_import(params['doc_file'], true)
	  if(@error)
  	  @success = [@error]
  	else
  	 @success = ["success: " + params['doc_file'].original_filename]
  	end
  	
		render :action => :create
	end
	
private

  # import a single library into the database
  def do_import(file, tempfile = false)
    init_classes()
	
	  @connection = ActiveRecord::Base.connection

    if(@connection.class.to_s =~ /mysql/i)
      # check to see if the connection is MySQL, if so then we have created some 
      # optimizations for MySql inserts          
	    @connection_type = "mysql"
	  else
	    @connection_type = "other"
	  end	
		
    # Lookup hash used to map ids in the YAML file to database IDs
    lookup = {}
		
    # Lookup hash used to keep columns around so that they do not need to be
    # recreated each time
    @col_hash = Hash.new
	  
	  # should we be reading the file passed in, or is it a file stream already
    if(tempfile)
      file_name = file.original_filename
    else
      file_name = file
    end
		
    match = /([a-zA-Z0-9]+)-([0-9]+)\.([0-9]+)\.([0-9]+)\.out/.match(file_name)
    if(!match)
      @error = "File name must have the format name-major.minor.release.out, ex: rails-1.2.1.out"
      return
    end		

    # measure the time it takes to do the DB inserts
    start = Time.now
    count = 0
    # Set the logging level to ERROR so that we do not output SQL when we are debugging
    # that really slows things down
    loglevel = logger.level
    logger.level = Logger::ERROR
    
    ActiveRecord::Base.connection.transaction do
      autocommit(false)    
      # Create a new library object
      @library = RaLibrary.new({:name => match[1], :major => match[2], :minor => match[3], :release => match[4]})		
      @library.current = false
      @library.date = DateTime.now
		
      if(@library.find_lib == nil)
        @library.calc_version 			  
        @library.save!
        # ok now we need to see if the library version that we uploaded is the most recent version of this library			
        higher_version = RaLibrary.find(:first, :conditions => ["name = ? AND version > ?", @library.name, @library.version])
        if(higher_version == nil)
          # if our version is the most recent remove the current status from all the current entries
          currents = RaLibrary.find(:all, :conditions => ["name = ? AND current = ?", @library.name, true])
          if(currents)
            currents.each do |c|
              c.current = false
              c.save!
            end
          end
			  end
        # now set the status of this library to be most recent and save it
			  @library.current = true
			  @library.save!
    	else
    	  @error = "Could not import library " + file_name + " already exists"
    	  return
    	end 	
      
      # Read in the YAML file	
      if(!tempfile)
        file = File.open(file)
      end
      
      yp = YAML::load_documents( file ) { |doc|
        # if this is a library record then merge the attributes
        # with our library and save it (can provide more information)
        if(doc.class.to_s == RaLibrary.to_s)
		      # if there is a 'main' attribute it will be the name of the 
		      # file that should be displayed as the home page for this library
		      # this should be translated to the container id
		      if(doc.attributes['home_page'] != nil)
		        home_page = RaContainer.find(:first, :conditions => ["full_name = ? AND ra_library_id = ?", doc.home_page, @library.id])		      
		        if(home_page != nil)
  		        @library.main_container_id = home_page.id
		        end      
		      end
		      
		      attr = doc.attributes
		      attr.delete("home_page")
		      @library.update_attributes(attr)
		    else
		      # Each record has a unique id. This id changes though when we insert it into the
		      # database. This would not be a problem except that all of the records are associated 
		      # by these ids so when a record is inserted into the DB we need to make sure the associations are
		      # updated. get_ids takes care of this updating.
		      #
		      # IMPORTANT NOTE: This requires that the YAML is written out in the correct order so that we always insert
		      # a record before we need its id for an association		  	  		    		   		   		  
 		      id = doc.id
		      get_ids(doc, lookup)
		      lookup[id] = insert_object(doc)				  
		      count = count + 1
		    end
		  }		
	 	
	 	  if(!tempfile)
	 	    file.close
	 	  end
 	  autocommit(true)	 	  
	  end
 	  
		logger.level = loglevel			 		  	 
		@total_time = Time.now - start	
		@total_count += count
  end

	def insert_object(obj) 			  
    # We don't want to  use the ActiveRecord::Base.save method because it is slow
	  # ~1300 inserts on a MySQL DB MyIASM table on windows is 5.7 seconds with this method 
	  # and 17.5 seconds using .save  	 
    unless(@col_hash[obj.class.to_s])
      @col_hash[obj.class.to_s] = column_list(obj.attributes.keys.reject! { |key| key =~ /^id$/ })
    end
    columns = @col_hash[obj.class.to_s]
    attributes = obj.attributes
    attributes.delete('id') # remove the id column
    values = value_list(attributes.values) if attributes  
    val = @connection.insert "INSERT INTO #{obj.class.table_name} (#{columns}) VALUES (#{values})" if values
 	end
  
  # Create a list of column names from an array of strings
  def column_list(keys)
    columns = keys.collect{ |column_name| ActiveRecord::Base.connection.quote_column_name(column_name) }
    columns.join(", ")
  end

  # Create a list of insertable values from an array of strings
  def value_list(values)
    values.map { |v| ActiveRecord::Base.connection.quote(v).gsub('\n', "\\n").gsub('\r', "\\r") }.join(", ")
  end		
		
	# Lookup the database ids for all the associations for this type of object
	def get_ids(doc, lookup)		
		case(doc.class.superclass.to_s)
			when RaCodeObject.to_s
				doc.ra_container_id = lookup[doc.ra_container_id]
				doc.file_id = lookup[doc.file_id]
			when RaContainer.to_s
				doc.parent_id = lookup[doc.parent_id]
				doc.ra_comment_id = lookup[doc.ra_comment_id]
				doc.ra_library_id = @library.id				
		end
		
		puts "#{doc.class.to_s} - #{doc.id}"	
		pp doc.attributes
		puts "**"
		
		case(doc.class.to_s)
	    when RaClass.to_s
	        doc.file_id = lookup[doc.file_id]
	    when RaModule.to_s
          doc.file_id = lookup[doc.file_id]	    
			when RaMethod.to_s
				doc.ra_container_id = lookup[doc.ra_container_id]
				doc.ra_comment_id = lookup[doc.ra_comment_id]
				doc.ra_source_code_id = lookup[doc.ra_source_code_id]
				doc.file_id = lookup[doc.file_id]				
			when RaInFile.to_s
				doc.ra_container_id = lookup[doc.ra_container_id]
		end
	end
	
    # Try and avoid errors for PostgreSQL and maybe other databases too.
    # If it fails, we log an exception instead of putting up an error page
    # because we can still complete the mission, just slower?  
	def autocommit(state=true)
	  begin
	    ActiveRecord::Base.connection.execute('SET AUTOCOMMIT = ' + (state ? '1' : '0') )
	  rescue
	    begin
	      ActiveRecord::Base.connection.execute( state ? 'BEGIN' : 'COMMIT' )
	    rescue Exception => e
	      logger.info "Oops. #{e.to_s}\n" + e.backtrace.join + "\n"
	    end
	  end
	end	
	
  # if none of these classes has been previously used then the 
  # YAML load will fail because it will not find the class to be able to
  # instantiate it, not sure why this happens, but this here fixes that issue
  # by creating an instance of each class needed	
  def init_classes()
	    c = RaCodeObject.new
	    c = RaInFile.new
	    c = RaFile.new
	    c = RaSourceCode.new
	    c = RaComment.new
	    c = RaMethod.new
	    c = RaContainer.new
	    c = RaLibrary.new
	    c = RaAttribute.new
	    c = RaClass.new
	    c = RaConstant.new
	    c = RaInclude.new
	    c = RaRequire.new	
	    c = RaModule.new
	    c = RaAlias.new  	
	end	
end