class RaCodeObject < ActiveRecord::Base
  belongs_to :ra_container
  
  TYPE_REQUIRE = 'RaRequire'
  TYPE_INCLUDE = 'RaInclude'
  TYPE_CONSTANT = 'RaConstant'
  TYPE_ATTRIBUTE = 'RaAttribute'
end
