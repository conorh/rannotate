class RaLibrary < ActiveRecord::Base

	validates_numericality_of :major, :minor, :release
	validates_length_of :name, :maximum => 128
	validates_presence_of :name		
	
	def before_save
		@version = calc_version_int
	end

	def calc_version_int
		if(@major == nil || @minor == nil || @release == nil)
			return "error";
		end
				
		return (@major * 1000) + (@minor * 100) + (@release * 10)
	end			
		
	def validate
		if RaLibrary.find(:first, :conditions => ["name = ? AND version = ?", @name, calc_version_int()])
			errors.add_to_base("A library with this name and version already exists")				
		end
							
		if(!errors.empty?)
			return false
		end			
	end

end
