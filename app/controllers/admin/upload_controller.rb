class Admin::UploadController < ApplicationController
	def index	
		@library = RaLibrary.new()
	end
	
	def import
		@connection = ActiveRecord::Base.connection
		
		# Lookup hash used to map ids in the YAML file to database IDs
		lookup = {}
		
		# Lookup hash used to keep columns around so that they do not need to be
		# recreated each time
		@col_hash = Hash.new
		
		ActiveRecord::Base.connection.transaction do	
		
			# Create a new library object		
			@library = RaLibrary.new(@params['library'])
			@library.save		
		
			# ok now we need to see if the library version that we uploaded is the most recent version of this library			
			higher_version = RaLibrary.find(:first, :conditions => ["name = ? AND version > ?", @params['library']['name'], @library.version])
			if(higher_version == nil)
				# if our version is the most recent remove the current status from all the current entryes
				currents = RaLibrary.find(:all, :conditions => ["name = ? AND current = ?", @params['library']['name'], true])
				if(currents)
					currents.each do |c|
						c.current = false
						c.save
					end
				end
				# now set the status of this library to be most recent and save it
				@library.current = true
				@library.save
			end						
			
						
			if(@library.valid?)
				# measure the time it takes to do the DB inserts
		 		start = Time.now
	 	
			 	# Set the logging level to ERROR so that we do not output SQL when we are debugging
		 		# that really slows things down
	 			loglevel = logger.level
	 			logger.level = Logger::ERROR
				# Read in the YAML file			
				yp = YAML::load_documents( @params['doc_file'] ) { |doc| 
					# Each record has a unique id. This id changes though when we insert it into the
					# database. This would not be a problem excep that all of the records are associated 
					# by these ids so when a record is inserted into the DB we need to make sure the associations are
					# updated. get_ids takes care of this updating.
					# IMPORTANT NOTE: This requires that the YAML is written out in the correct order so that we always insert
					# a record before we need its id for an association.
					id = doc.id
					get_ids(doc, lookup)
					doc.id = nil	
					lookup[id] = insert_object(doc)
				}		
				
				@total_time = Time.now - start		
				logger.level = loglevel
			end
		end			
		
		render :action => :index		
	end
	
private

	# Insert an active record object into the DB
	# We don't use the ActiveRecord::Base.save method because it is slow
	# ~1300 inserts on a MySQL DB MyIASM table on windows is 5.7 seconds with this method 
	# and 17.5 seconds using .save
	def insert_object(obj)	
		unless(@col_hash[obj.class.to_s])
			@col_hash[obj.class.to_s] = column_list(obj.attributes.keys)
		end
		columns = @col_hash[obj.class.to_s]
		values = value_list(obj.attributes.values)
		val = @connection.insert "INSERT INTO #{obj.class.table_name} (#{columns}) VALUES (#{values})"
	end
		
  # Create a list of column names from an array of strings
  def column_list(keys)
    columns = keys.collect{ |column_name| ActiveRecord::Base.connection.quote_column_name(column_name) }
    columns.join(", ")
  end

  # Create a list of insertable values from an array of strings
  def value_list(values)
    values.map { |v| ActiveRecord::Base.connection.quote(v).gsub('\\n', "\n").gsub('\\r', "\r") }.join(", ")
  end		
		
	# Lookup the database ids for all the associations for this type of object
	def get_ids(doc, lookup)
		
		case(doc.class.superclass.to_s)
			when RaCodeObject.to_s
				doc.ra_container_id = lookup[doc.ra_container_id]
			when RaContainer.to_s
				doc.parent_id = lookup[doc.parent_id]
				doc.ra_comment_id = lookup[doc.ra_comment_id]
				doc.ra_library_id = @library.id
		end
		
		case(doc.class.to_s)
			when RaMethod.to_s
				doc.ra_container_id = lookup[doc.ra_container_id]
				doc.ra_comment_id = lookup[doc.ra_comment_id]
				doc.ra_source_code_id = lookup[doc.ra_source_code_id]
			when RaInFile.to_s
				doc.ra_container_id = lookup[doc.ra_container_id]
		end
	end
end
