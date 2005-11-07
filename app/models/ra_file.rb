class RaFile < RaContainer

  def RaFile.type_string
    return 'file'
  end

  def relative_name
    return @name
  end
  
  def relative_name=(new_value)
    @name = new_value
  end
  
  def absolute_name
    return @full_name
  end
  
  def absolute_name=(new_value)
    @full_name = new_value
  end    

end
