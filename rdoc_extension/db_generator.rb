require 'erb'
require 'dbi'

# This class processes the results of the rdoc parsing and outputs the results
# into a database. The table layout of this database is contained in the rannotate
# project in the db directory.
#
# How does it work?
# Rdoc calls the generate method of this class from inside of rdoc.rb. By the 
# time rdoc calls the generate method it has parsed all of the source files 
# and has put them in a tree structure. The details of this tree structure 
# are in the file code_objects.rb. 
#
# generate gets passed an array of 'toplevel' objects which are files
# we process these toplevel objects recursively, extracting all of the code 
# objects they contain: classes, modules, methods, attributes etc..
# the Ruby::DBI library is used to insert the records into the database

module Generators

  # This generator takes the output of the rdoc parser
  # and turns it into a bunch of INSERT sql statements for a database
  class DBGenerator                 

    TYPE = {:file => 1, :class => 2, :module => 3 }
    VISIBILITY = {:public => 1, :private => 2, :protected => 3 }
        
    # Create a new DB Generator object (used by RDoc)
    def DBGenerator.for(options)
      new(options)
    end
        
    # Greate a new generator and open up the file that will contain all the INSERT statements
    def initialize(options) #:not-new:
      begin
      	@options = options
      
      	# set up a hash to keep track of all the classes/modules we have processed
      	@already_processed = {}        
      
      	@main_page = @options.main_page
      	# this boolean keeps track of whether we have found the main page or not
      	@main_page_found = false  
      
      	# connect to a datbase
      	@db = connect_to_db(@options.template) 
      
      	Attempt to insert the library name and version into the database
      	res = insert_library(@options.opname)
      	unless(res)
      		puts "\n" + res + "\n"
    		return
      	end
      
	    # this keeps track of unique id sequences for the tables
      	@seq = {}
      	@total_inserts = 0
      rescue
      	puts "DB GENERATOR ERROR: " + $!
      	raise
      end      
    end

    # Rdoc passes in TopLevel objects from the code_objects.rb tree (all files)
    def generate(files)
      start = Time.now    
      # Each object passed in is a file, process it
      files.each { |file| process_file(file) }
     
      if(@main_page != nil && @main_page_found == false)
        puts "\n***** DB GENERATOR WARNING: Could not find main page '" + @main_page + "'\n"
      end      
      
      @db.disconnect
      
      total = Time.now - start
      puts "\n Total time to insert into DB = " + total.to_s
      puts "\n Total inserts = " + @total_inserts.to_s
      puts "\n Time per insert = " + (total / @total_inserts).to_s
    end

    private

	def connect_to_db(connection_string)
      if(connection_string == nil)
 		raise "Missing db_generator config --template=DBI:xxx:db#user#pass"      
      end
      
      result = connection_string.split('#')
      
      if(result == nil || result.length != 3)
      	raise "Incorrect db_generator config must use format --template=DBD:xxx:db#user#pass"  
      end
      
	  return DBI.connect(result[0], result[1], result[2])	
	end

    # process a file from the code_object.rb tree
    def process_file(file)
      id = insert_file(file)
              
      # Process all of the objects that this file contains
      file.method_list.each { |child| insert_method(child, id) }
      file.aliases.each { |child| insert_alias(child, id) }
      file.constants.each { |child| insert_constant(child, id) }
      file.requires.each { |child| insert_require(child, id) }
      file.includes.each { |child| insert_include(child, id) }
      file.attributes.each { |child| insert_attribute(child, id) }  
    
      # Recursively process contained subclasses and modules 
      file.each_classmodule do |child| 
          process_class_or_module(child, file, id)      
      end       
      
    end           
    
    # Process classes and modiles   
    def process_class_or_module(obj, parent, parent_id)
      obj.is_module? ? type = 'RaModule': type = 'RaClass'
    
      # One important note about the code_objects.rb structure. A class or module
      # definition can be spread a cross many files in Ruby so code_objects.rb handles
      # this by keeping only *one* reference to each class or module that has a definition
      # at the root level of a file (ie. not contained in another class or module).
      # This means that when we are processing files we may run into the same class/module
      # twice. So we need to keep track of what classes/modules we have
      # already seen and make sure we don't create two INSERT statements for the same
      # object.
      if(!@already_processed.has_key?(obj.full_name)) then      
        id = insert_class_or_module(obj, parent_id, type)
        @already_processed[obj.full_name] = id        
          
        # Process all of the objects that this class or module contains
        obj.method_list.each { |child| insert_method(child, id) }
        obj.aliases.each { |child| insert_alias(child, id) }
        obj.constants.each { |child| insert_constant(child, id) }
        obj.requires.each { |child| insert_require(child, id) }
        obj.includes.each { |child| insert_include(child, id) }
        obj.attributes.each { |child| insert_attribute(child, id) } 
        obj.in_files.each { |child| insert_in_file(child, id) }  
      end
      
      # since we have already processed this object and inserted it
      # we have it's id so get that id for use with child objects
      id = @already_processed[obj.full_name]
      # Recursively process contained subclasses and modules 
      obj.each_classmodule do |child| 
      	process_class_or_module(child, obj, id) 
      end
    end       
    
    def insert_library(libver)
    	lib, ver = libver.split(':')
    	
		if(lib == nil || ver == nil)
			return "Error: --opname must have the format '--opname=lib:1.2.11'"
		end    	
    	    	    	
    	major,minor,release = ver.split('.')
    	version_int = (major.to_i * 1000) + (minor.to_i * 100) + (release.to_i * 10)
    	    
		# First check to see if this library name/version exists already in the DB
		row = @db.select_one("SELECT * FROM ra_libraries WHERE name = ? AND version = ?", lib, version_int)    	
    	if(row)
    		return "Error: Library " + lib + " version " + ver + " already exists in the database"    	
    	end
    
    	@library_id = get_next_id('ra_libraries')   
    	sql = "INSERT INTO ra_libraries (id, name, version, major, minor, release) VALUES(?,?,?,?,?,?)"    	
    	@db.execute(sql, @library_id, lib, version_int, major, minor, release)
    	
    	@total_inserts += 1
    	
    	return nil
    end
    
    def insert_method(obj, parent_id)  
    	comment_id = insert_comment(obj)    
 
    	unless @source_stmt
    		@source_stmt = @db.prepare("INSERT INTO ra_source_codes (id, source_code) VALUES (?, ?)")
    	end    	
    	source_id = get_next_id('ra_source_codes')       	
    	@source_stmt.execute(source_id, get_source_code(obj))
    				
		unless @method_stmt
			sql = "INSERT INTO ra_methods (id, ra_container_id, name, parameters, block_parameters, singleton, visibility, force_documentation, ra_comment_id, ra_source_code_id) ";
			sql += "VALUES(?,?,?,?,?,?,?,?,?,?)"
			@method_stmt = @db.prepare(sql)
		end
    	method_id = get_next_id('ra_methods')
		@method_stmt.execute(method_id, parent_id, obj.name, 
		  obj.params, obj.block_params, bool_to_int(obj.singleton), VISIBILITY[obj.visibility],
		  bool_to_int(obj.force_documentation), comment_id, source_id
		);
		
    	@total_inserts += 2		
		return method_id 	                          
    end
    
    def insert_file(file)    	
    	comment_id = insert_comment(file)
 	
		unless @file_stmt			
			sql = "INSERT INTO ra_containers(id, ra_library_id, type, parent_id, name, full_name, superclass, ra_comment_id)";
			sql += " VALUES(?, ?, 'RaFile', 0, ?, ?, '', ?)"
			@file_stmt = @db.prepare(sql)
		end
		
		# If a 'home page' is specified then check to see if this file is the home page
		# if it is then give it the id 1 and insert it into the DB
        if(@main_page != nil && @main_page == file.file_absolute_name)
          file_id = 1      
          @main_page_found = true
        else
          file_id = get_next_id('ra_containers')
       	end	    	
    	
		@file_stmt.execute(file_id, @library_id, file.file_relative_name, file.file_absolute_name, comment_id)		
		
    	@total_inserts += 1		
		return file_id
    end
                
    def insert_class_or_module(obj, parent_id, type)
    	comment_id = insert_comment(obj)

    	unless @clsmod_stmt    	   	
			sql = "INSERT INTO ra_containers(id, ra_library_id, type, parent_id, name, full_name, superclass, ra_comment_id)";
			sql += " VALUES(?, ?, '#{type}', ?, ?, ?, ?, ?)"
			@clsmod_stmt = @db.prepare(sql)
		end
    	class_id = get_next_id('ra_containers') 		
		@clsmod_stmt.execute(class_id, @library_id, parent_id, obj.name, obj.full_name, obj.superclass, comment_id)
		
    	@total_inserts += 1		
		return class_id
    end     
    
    # Each class or module contains a list of the files that it is defined in
    # this method adds that list of files to the output
    def insert_in_file(obj,parent_id)
    	comment_id = insert_comment(obj)
 
    	unless @infile_stmt
			sql = "INSERT INTO ra_in_files(id, file_name, ra_container_id)"
	     	sql += "VALUES(?, ?, ?)"
	    	@infile_stmt = @db.prepare(sql)
	    end
    	in_file_id = get_next_id('ra_in_files')	    
    	@infile_stmt.execute(in_file_id, obj.file_absolute_name, parent_id)
 
     	@total_inserts += 1
    	return in_file_id    	
    end   
    
    def insert_alias(obj, parent_id)
    	return insert_code_object(obj, parent_id, 'RaAlias', obj.old_name, obj.new_name)
    end
    
    def insert_constant(obj, parent_id)
    	return insert_code_object(obj, parent_id, 'RaConstant', obj.name, obj.value)
    end
    
    def insert_attribute(obj, parent_id)
    	return insert_code_object(obj, parent_id, 'RaAttribute', obj.name, '', VISIBILITY[obj.visibility], obj.rw) 
    end
    
    def insert_require(obj, parent_id)
    	return insert_code_object(obj, parent_id, 'RaRequire', obj.name)
    end
    
    def insert_include(obj, parent_id) 
    	return insert_code_object(obj, parent_id, 'RaInclude', obj.name)
    end       
   
    def insert_code_object(obj, parent_id, type, name, value = '', visibility = 0, read_write = '')
    	comment_id = insert_comment(obj)
 		unless @codeobj_stmt
	 		sql = "INSERT INTO ra_code_objects (id, ra_container_id, type, name, value, visibility, read_write, comment)"
 			sql += " VALUES(?,?,?,?,?,?,?,?)" 		
 			@codeobj_stmt = @db.prepare(sql)
 		end
 		id = get_next_id('ra_code_objects') 		
 		@codeobj_stmt.execute(id, parent_id, type, name, value, visibility, read_write, obj.comment)   
    	@total_inserts += 1 		
    end   
    
    def insert_comment(obj)
  		unless @comment_stmt
			@comment_stmt = @db.prepare("INSERT INTO ra_comments(id, comment) VALUES(?,?)")
		end
  		comment_id = get_next_id('ra_comments')		
		@comment_stmt.execute(comment_id, obj.comment)
    	@total_inserts += 1		
		return comment_id	   	
    end           
             
	# get the next unique ID      
    def get_next_id(name)
      # look at the table with the name passed in and get
      # the highest current ID value in that table
      unless @seq[name]
      	row = @db.select_one("SELECT MAX(id) FROM " + name)
      	if(row == nil || row[0] == nil)      	 	
  			@seq[name] = 2
  		else
  			@seq[name] = row[0]
  		end
      end
      
      @seq[name] = @seq[name] + 1
      return @seq[name]
    end                 
    
    # Transform true/false -> 1/0
    def bool_to_int(bool_val)
      if(bool_val == nil)
        return 0
      end
      return bool_val ? 1 : 0
    end
    
    # get the source code
    def get_source_code(method)
      src = ""
	  if(ts = method.token_stream)    
	    ts.each do |t|
	    next unless t    			
	      src << t.text
	    end
      end
      return src
    end
         
  end

end