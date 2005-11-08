class RaAttribute < RaCodeObject
  belongs_to :ra_container, { :foreign_key => "container_id" }
  
  def RaAttribute.type_string
  	"attribute"
  end
end
