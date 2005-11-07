module Admin::NotesHelper

	def get_periods(select)		
		return options_for_select({
			'minute(s)' => 'minutes', 
			'hour(s)' => 'hours', 
			'day(s)' =>  'days', 
			'week(s)' => 'weeks', 
			'month(s)' => 'months'
		}, select)
	end

	def get_order_fields(select)
		return options_for_select({	
			'Created Date' => 'created_at', 
			'Category' => 'category', 
			'Email' => 'email', 
			'Content Length' => 'content_length',
			'IP Address' => 'ip_address',					
			'Id' => 'id'
		}, select)		
	end
	
	def get_order_directions(select)	
		return options_for_select({	 'Ascending' => 'asc', 'Descending' => 'desc' }, select)
	end 
		
end
