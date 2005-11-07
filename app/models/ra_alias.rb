class RaAlias < RaCodeObject
  def old_name
    return @name
  end
  
  def old_name=(new_value)
    @name = new_value
  end
  
  def new_name
    return @value
  end
  
  def new_name=(new_value)
    @value = new_value
  end    
end