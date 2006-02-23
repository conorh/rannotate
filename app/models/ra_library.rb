class RaLibrary < ActiveRecord::Base

	validates_numericality_of :major, :minor, :release, :version
	validates_length_of :name, :maximum => 128
	validates_presence_of :name	

	# return a string with the version in the form major.minor.release ex. 1.2.11
	def ver_string
		return @major.to_s + "." + @minor.to_s + "." + @release.to_s
	end
	
	# calculate a single integer from the version string
	def RaLibrary.ver_string_to_int(ver)			
		match = /([0-9]+)\.([0-9]+)\.([0-9]+)/.match(ver)
		return RaLibrary.calc_version_int(match[1].to_i, match[2].to_i, match[3].to_i)
	end

	# Calculates an integer representation of the major/minor/release version
	def RaLibrary.calc_version_int(major, minor, release)				
		return (major.to_i * 10000) + (minor.to_i * 100) + (release.to_i * 1)
	end			
		
	def validate_on_create
		self.version = RaLibrary.calc_version_int(major.to_i, minor.to_i, release.to_i)	
	
		if RaLibrary.find(:first, :conditions => ["name = ? AND major = ? AND minor = ? and release = ?", name, major, minor, release])
			errors.add_to_base("A library with this name and version already exists")				
		end
							
		if(!errors.empty?)
			return false
		end			
	end

end
