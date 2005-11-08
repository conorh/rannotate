class RaConstant < RaCodeObject
  belongs_to :ra_container, { :foreign_key => "container_id" }
  
  def RaConstant.type_string
  	"constant"
  end
end
