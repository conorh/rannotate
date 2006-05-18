class Note < ActiveRecord::Base	
    belongs_to :ra_container
	
	# This attribute is used to store the URL of the documentation this note refers to
	# this is not stored in the DB as it can change depending on the URL that the documentation is accessed from
	attr_accessor :content_url, :skip_ban_validation
	attr_accessor :ref_id, :ref_type
	
	validates_length_of :email, :in => 5..40
	validates_length_of :text, :in => 10..5000
	validates_presence_of :container_name
	validates_presence_of :note_group

	def initialize(params = nil)
		super(params)
		@skip_ban_validation = false
	end

	# This validate method checks to see if this ip_address has posted already in the last 1 minute
	# It also checks to see if the user's IP address is in the list of banned IP addresses
	# TODO: Finish this method and make each of these checks an application configurable option
	def validate
		if(@skip_ban_validation == false)		
			searchIp = ip_address[0,ip_address.rindex('.')]
			ban = Ban.find(:first, :conditions => ["? LIKE ip_filter", searchIp])
			if(ban != nil)
				errors.add_to_base("Your IP subnet has been banned from posting due to abuse. Please contact the system administrator for more information")
			end			
	
			timeLimit = DELAY_BETWEEN_POSTS.ago
			found = Note.find(:first, :conditions => ["created_at > ? AND ip_address = ?", timeLimit, ip_address])
			if(found != nil)
				errors.add_to_base("Your IP address has already posted in the last minute, please wait a minute or so before posting again.")				
			end
		end
		
		if(!errors.empty?)
			return false
		end
	end

	# This builds the SQL filter conditions and sort order from the hash of parameters that is passed in
	# TODO: This could probably use the NoteFilter class instead of taking in parameters
	# TODO: It is somewhat generic using RecordFilter, but it could be made more so
	def Note.find_with_filter(params)	  

		filter = RecordFilter.new
	
		text_fields = %w{id container_name note_group note_type text email ip_address}
		text_fields.each { |name|
			filter.addLike(name, params[name])
		}		
		
		allowed_period_types = %w{minutes hours days weeks months}
		if(params[:period_type] && allowed_period_types.include?(params[:period_type]))		
			since = params['period_count'].to_i.send(params[:period_type]).ago.strftime("%Y-%m-%d %H:%M:%S")
			filter.addGreaterThan('created_at', since);							
		end
		
		filter.addGreaterThan('created_at', create_datetime(params['start_post_time']), :use => params['start_post'])
		filter.addLessThan('created_at', create_datetime(params['end_post_time']), :use => params['end_post'])
		filter.addGreaterThan('updated_at', create_datetime(params['start_update_time']), :use => params['start_update'])
		filter.addLessThan('updated_at', create_datetime(params['end_update']), :use => params['end_update'])
		
		find_params = Hash.new	
		conditions = filter.getConditions()
		if(conditions.length > 1)
			find_params[:conditions] = conditions
		end
		
		# TODO: This is open to SQL injection attacks, need to fix that...
		if(params[:order_by] && params[:order_direction])
			find_params[:order] = params[:order_by] + ' ' + params[:order_direction];
		end
						
		if(find_params.length > 0)
			return Note.find(:all, find_params)
		else
			return Note.find(:all)
		end																
	end	

    # display a string that specifies what this note is commenting
	def get_display
     case self.note_type
	   when RaModule.to_s then return container_name
	   when RaClass.to_s then return container_name 
	   when RaFile.to_s then return container_name                
	   when RaMethod.to_s then return "Method " + note_group + " of " + container_name
	   when "RaChildren" then return "Children section of " + container_name	   
	   when RaInFile.to_s then return "InFiles section of " + container_name
	   when RaAttribute.to_s then return "Attributes section of " + container_name
	   when RaConstant.to_s then return "Constants section of " + container_name
	   when RaInclude.to_s then return "Includes section of " + container_name
	   when RaRequire.to_s then return "Requires section of " + container_name
	   when RaAlias.to_s then return "Aliases section of " + container_name
	   when "index" then return "Index page"
      end
      
      return container_name + " - " + note_group
	end	

protected

	# Create a SQL datetime from the select_datetime form helper fields
	def Note.create_datetime(values)
		if(values == nil)
			return nil
		end
	
		date = values[:year] + '-' + values[:month] + '-' + values[:day] + ' ' + values[:hour] + ':' + values[:minute]
		return date
	end			

end

# This class builds up a series of SQL conditions and values and will then output them so that
# they can be used in a SELECT query
class RecordFilter

	def initialize
		@sql = Array.new
		@values = Array.new
	end
	
	def addConstraint(name, value, constraint, params = {})
		if(params[:use] && params[params[:use]] == nil)
			return
		end
		
		if(value == nil || value == '')
			return
		end
		
		@sql.push(name + ' ' + constraint)
		@values.push(value)
	end		
	
	def addEquals(name, value, params = {})	
		addConstraint(name, value, '= ?', params);
	end
	
	def addLike(name, value, params = {})
		if(value == nil || value == '')
			return
		end
		addConstraint(name, '%' + value + '%', 'LIKE ?', params);
	end
	
	def addLessThan(name, value, params = {})
		addConstraint(name, value, '< ?', params);
	end
	
	def addGreaterThan(name, value, params = {})
		addConstraint(name, value, '> ?', params);		
	end
	
	def addGreaterThanDate(name, value, params = {})
		addConstraint(name, value, '< ?', params);	
	end
	
	def addLessThanDate(name, value, params = {})
		addConstraint(name, value, '> ?', params)			
	end
	
	def getConditions
		sqlString = String.new

    for i in 0..@values.length-1
    	sqlString += @sql[i]
    	if(i != @values.length - 1)
    		sqlString += ' AND ';
    	end
    end				
		
		return [sqlString, @values].flatten		
	end
	
end