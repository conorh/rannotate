class RaConstant < RaCodeObject
  belongs_to :ra_container, { :foreign_key => "container_id" }
end
