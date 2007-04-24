class RaLibrary < ActiveRecord::Base
    has_many :RaContainer, :dependent => :delete_all
    
	validates_numericality_of :major, :minor, :release, :version
	validates_length_of :name, :maximum => 128
	validates_presence_of :name	

	# return a string with the version in the form major.minor.release ex. 1.2.11
	def ver_string
		return major.to_s + "." + minor.to_s + "." + release.to_s
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
	
	# Calculates the integer representation of the version information and stores it in in the version attribute
	def calc_version
	   self.version = RaLibrary.calc_version_int(major.to_i, minor.to_i, release.to_i)	
	end
	
	# during the validation process this method is called, it calculates the version integer
	def validate
		self.version = RaLibrary.calc_version_int(major.to_i, minor.to_i, release.to_i)		
	end
	
	# A helper method to find the a library when you have the name and release information
	def find_lib
	    return RaLibrary.find(:first, :conditions => ["name = ? AND major = ? AND minor = ? AND `release` = ?", name, major, minor, release]) 
	end
	
	# on create checks to see if a library with this version and name exists already
	def validate_on_create
		self.version = RaLibrary.calc_version_int(major.to_i, minor.to_i, release.to_i)
			
		if find_lib
			errors.add_to_base("A library with this name and version already exists")				
		end
							
		if(!errors.empty?)
			return false
		end
	end

end
