# This model is used to store the parameters used to display a filtered list of Note models
# TODO: Right now this is not getting reloaded by rails when it is modified.. need to figure out how to fix that
class NoteFilter

	attr_accessor :id, :category, :name, :text, :email, :ip_address
	attr_accessor :period_count, :period_type
	attr_accessor :order_by, :order_direction
	attr_accessor :number_per_page
	attr_accessor :show_summarized
	attr_accessor :start_post, :start_post_time, :end_post, :end_post_time
	attr_accessor :start_update, :start_update_time, :end_update, :end_update_Time

	DEFAULT_PER_PAGE = 100
	DEFAULT_PERIOD_COUNT = 1
	DEFAULT_SHOW_SUMMARIZED = 1
	DEFAULT_ORDER_BY = 'created_at'
	DEFAULT_ORDER_DIRECTION = 'desc'
	DEFAULT_PERIOD_TYPE = 'days'
	
	def initialize(params)
		# set some default values
		# TODO: is there a better way of doing this?
		@number_per_page = DEFAULT_PER_PAGE;
		@period_count = DEFAULT_PERIOD_COUNT;
		@show_summarized = DEFAULT_SHOW_SUMMARIZED;
		@order_by = DEFAULT_ORDER_BY
		@order_direction = DEFAULT_ORDER_DIRECTION
		@period_count = DEFAULT_PERIOD_COUNT
		@period_type = DEFAULT_PERIOD_TYPE
		
		if(params == nil)			
			return
		end
		
		# fill in all the accessors with the values from the parameters		
		# if this is ever opened to the public and not just an admin page DONT use this. It is insecure.
		# you could execute any method= by passing in a paramter
		# we would need to vet the params somehow
		methodList = NoteFilter.public_instance_methods
		params.keys.each { |key|	
			if(methodList.include?(key + '='))
				self.send(key + '=', params[key])
			end
		}
		
	end

end