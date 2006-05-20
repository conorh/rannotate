require 'yaml'

# This class processes the results of the rdoc parsing and outputs YAML formatted 
# classes that can then be imported into the database using the Rannotate web app.
#
# The YAML that is generated is quite generic and could be used by any application
# to see the DB structure that is required look at the DB schema that the rannotate
# web application creates (all the tables beginning with ra_)
#
# How does it work?
# Rdoc calls the generate method of this class from inside of rdoc.rb. By the 
# time rdoc calls the generate method it has parsed all of the source files 
# and has put them in a tree structure. The details of this tree structure 
# are in the file code_objects.rb. 
#
# generate(files) gets passed an array of 'toplevel' objects which are files
# we process these toplevel objects recursivley extracting all of the code 
# objects they contain: classes, modules, methods, attributes etc..
#
# Example usage 
# rdoc --fmt=yaml --opname=activerecord-1.1.13 activerecord-1.1.13

module Generators

  class YAMLGenerator

    TYPE = {:file => 1, :class => 2, :module => 3 }
    VISIBILITY = {:public => 1, :private => 2, :protected => 3 }        
        
    # Create a new DB Generator object (used by RDoc)
    def YAMLGenerator.for(options)
      new(options)
    end
        
    # Greate a new generator and open up the file that will contain all the INSERT statements
    def initialize(options) #:not-new:
      @options = options
      
      # set up a hash to keep track of all the classes/modules we have processed
      @already_processed = {}      
      
      # sequences used to generate unique ids for inserts
      @seq = 1
            
      # An output filename must be specified on the commandline
      @output_file = @options.op_name
      if @output_file == nil || !(@output_file =~ /[a-zA-Z]+-[0-9]+\.[0-9]+\.[0-9]+/)
        puts "Error:"
      	puts "You must specify an output filename on the command line."
      	puts "and it must have the format: name-[major]-[minor]-[release"
      	puts "(matching the regex: [a-zA-Z]+-[0-9]+\.[0-9]+\.[0-9]+)"
      	puts "Ex: rdoc --fmt=yaml --opname=rannotate-1.2.1"
      	exit
      end  
                 
    end

    # Rdoc passes in TopLevel objects from the code_objects.rb tree (all files)
    def generate(files)   
      @f = File.new(@output_file + ".out", File::CREAT|File::TRUNC|File::RDWR) 
      
      @output = String.new
      
      # Each object passed in is a file, process it
      files.each { |file| process_file(file) }     
      
      @f << @output
      @f.close
    end

    private

    # process a file from the code_object.rb tree
    def process_file(file)
      putc('.')
      id = create_file(file)           
          
      # Process all of the objects that this file contains
      file.method_list.each { |child| process_method(child, file, id) }
      file.aliases.each { |child| process_alias(child, file, id) }
      file.constants.each { |child| process_constant(child, file, id) }
      file.requires.each { |child| process_require(child, file, id) }
      file.includes.each { |child| process_include(child, file, id) }
      file.attributes.each { |child| process_attribute(child, file, id) }   
    
      # Recursively process contained subclasses and modules 
       file.each_classmodule do |child| 
          process_class_or_module(child, file, id)      
      end       
      
    end
    
    # Process classes and modiles   
    def process_class_or_module(obj, parent, parent_id)    
      # One important note about the code_objects.rb structure. A class or module
      # definition can be spread a cross many files in Ruby so code_objects.rb handles
      # this by keeping only *one* reference to each class or module that has a definition
      # at the root level of a file (ie. not contained in another class or module).
      # This means that when we are processing files we may run into the same class/module
      # twice. So we need to keep track of what classes/modules we have
      # already seen and make sure we don't create two INSERT statements for the same
      # object.
      if(!@already_processed.has_key?(obj.full_name)) then      
        id = create_class_or_module(obj, parent_id)
        @already_processed[obj.full_name] = id        
          
        # Process all of the objects that this class or module contains
        obj.method_list.each { |child| process_method(child, obj, id) }
        obj.aliases.each { |child| process_alias(child, obj, id) }
        obj.constants.each { |child| process_constant(child, obj, id) }
        obj.requires.each { |child| process_require(child, obj, id) }
        obj.includes.each { |child| process_include(child, obj, id) }
        obj.attributes.each { |child| process_attribute(child, obj, id) } 
        obj.in_files.each { |child| process_in_file(child, obj, id) }  
      end
      
      id = @already_processed[obj.full_name]
      # Recursively process contained subclasses and modules 
      obj.each_classmodule do |child| 
      	process_class_or_module(child, obj, id) 
      end
    end       
    
    def output_yaml(c)
      @output << c.to_yaml()
      @output << "\n"    
    end
    
    def create_comment(obj)
      id = get_next_id(:comments)    
      c = RaComment.new({'id' => id, 'comment' => obj.comment}) 
      output_yaml(c)
      return id
    end
    
    def create_file(obj)
      comment_id = create_comment(obj)      
            
      id = get_next_id(:files)            
      c = RaFile.new({
        'name' => obj.file_relative_name,
        'type' => 'RaFile', 
        'id' => id, 
        'ra_comment_id' => comment_id,
        'ra_library_id' => 0,
        'full_name' => obj.file_absolute_name,
        'parent_id' => 0
      })
      
      output_yaml(c)
      return id  
    end
    
    def create_class_or_module(obj, parent_id)
      comment_id = create_comment(obj)      
      
      if(obj.is_module?)
        type = 'Module'
        c = RaModule.new
      else
        type = 'Class' 
        c = RaClass.new      
      end
          
      id = get_next_id(:type)
      c.attributes = {
        'name' => obj.name,
        'type' => 'Ra' + type,
        'id' => id, 
        'ra_comment_id' => comment_id,
        'ra_library_id' => 0,
        'full_name' => obj.full_name,
        'parent_id' => parent_id,
        'superclass' => obj.superclass
      }
      
      output_yaml(c)
      return id     
    end          
    
    def process_method(obj, parent, parent_id)  
      comment_id = create_comment(obj)
            
      source_id = get_next_id(:source)
      c = RaSourceCode.new({'id' => source_id, 'source_code' => get_source_code(obj)})
      output_yaml(c)         
       
      id = get_next_id(:methods)  
      c = RaMethod.new({
        'id' => id,
        'ra_comment_id' => comment_id,
        'visibility' => VISIBILITY[obj.visibility], 
        'name' => obj.name,
        'ra_container_id' => parent_id,
        'parameters' => obj.params,
        'singleton' => bool_to_int(obj.singleton),
        'force_documentation' => bool_to_int(obj.force_documentation),
        'block_parameters' => obj.block_params,
        'ra_source_code_id' => source_id
      })
      
      output_yaml(c)
      return id                                      
    end
    
    # Each class or module contains a list of the files that it is defined in
    # this method adds that list of files to the output
    def process_in_file(obj,parent,parent_id)
      id = get_next_id(:infile)
      
      c = RaInFile.new({ 
        'id' => id,
        'ra_container_id' => parent_id,
        'file_name' => obj.file_absolute_name        
      })
      
      output_yaml(c)
      return id                  
    end
    
    def process_alias(obj, parent, parent_id)
      id = get_next_id(:aliases)
      
      c = RaAlias.new({
        'id' => id,
        'name' => obj.old_name,
        'ra_container_id' => parent_id,
        'type' => 'RaAlias',
        'value' => obj.new_name,
        'comment' => obj.comment
      })
      output_yaml(c)
      return id    
    end
    
    def process_constant(obj, parent, parent_id)
      id = get_next_id(:constants) 
      
      c = RaConstant.new({
        'id' => id,
        'name' => obj.name,
        'ra_container_id' => parent_id,
        'type' => 'RaConstant',
        'value' => obj.value,
        'comment' => obj.comment
      })
      output_yaml(c)
      return id     
    end
    
    def process_attribute(obj, parent, parent_id)
      id = get_next_id(:attributes)   
      
      c = RaAttribute.new({
        'id' => id,
        'read_write' => obj.rw,
        'visibility' => VISIBILITY[obj.visibility],
        'name' => obj.name,
        'ra_container_id' => parent_id,
        'type' => 'RaAttribute',
        'comment' => obj.comment
      })
      output_yaml(c)
      return id             
    end
    
    def process_require(obj, parent, parent_id)
      id = get_next_id(:requires)
      c = RaRequire.new({
        'id' => id,
        'name' => obj.name,
        'ra_container_id' => parent_id,
        'type' => 'RaRequire',
        'comment' => obj.comment
      })
      output_yaml(c)
      return id
    end
    
    def process_include(obj, parent, parent_id) 
      id = get_next_id(:includes)   
      c = RaInclude.new({
        'id' => id,
        'name' => obj.name,
        'ra_container_id' => parent_id,
        'type' => 'RaInclude',
        'comment' => obj.comment
      })
      output_yaml(c)
      return id  
    end                       

	# get the next unique ID      
    def get_next_id(name = nil)
      @seq = @seq + 1
      return @seq
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

# The classes below emulate the ActiveRecord models used by Rannotate
# We emulate them so that we can output them to YAML and easily import them in the Rails App
# TODO: Investigate importing the active record models instead of creating these mock objects

class RaFile
  def initialize(attr)
    @attributes = attr
    @new_record = true
  end
end

class RaClass
  attr_accessor :attributes
  def initialize()
    @new_record = true
  end    
end

class RaModule
  attr_accessor :attributes
  def initialize()
    @new_record = true
  end
end
   
class RaCodeObject
  def initialize(attr)
    @attributes = attr
    @new_record = true
  end
end

class RaAlias
  def initialize(attr)
    @attributes = attr
    @new_record = true
  end
end

class RaConstant
  def initialize(attr)
    @attributes = attr
    @new_record = true
  end
end

class RaAttribute
  def initialize(attr)
    @attributes = attr
    @new_record = true
  end
end

class RaRequire
  def initialize(attr)
    @attributes = attr
    @new_record = true
  end
end

class RaInclude
  def initialize(attr)
    @attributes = attr
    @new_record = true
  end
end
  
class RaComment
  def initialize(attr)
    @attributes = attr
    @new_record = true
  end    
end

class RaInFile
  def initialize(attr)
    @attributes = attr
    @new_record = true
  end
end

class RaMethod
  def initialize(attr)
    @attributes = attr
    @new_record = true
  end
end

class RaSourceCode
  def initialize(attr)
    @attributes = attr
    @new_record = true
  end
end