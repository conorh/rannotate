# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/switchtower.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

task "ranapi" do
  require 'rdoc/rdoc'
  params = []
  params << "--fmt=yaml"
  params << "--opname=rails-1.0.0"
  dirs = []
  dirs << 'vendor/railsd/railties/README'  
  dirs << 'vendor/railsd/railties/CHANGELOG'
  dirs << 'vendor/railsd/railties/MIT-LICENSE'
  dirs << 'vendor/railsd/activerecord/README' 
  dirs << 'vendor/railsd/activerecord/CHANGELOG'
  dirs << 'vendor/railsd/activerecord/lib/'
  dirs << 'vendor/railsd/actionpack/README'
  dirs << 'vendor/railsd/actionpack/CHANGELOG'
  dirs << 'vendor/railsd/actionpack/lib/'
  dirs << 'vendor/railsd/actionmailer/README'
  dirs << 'vendor/railsd/actionmailer/CHANGELOG'
  dirs << 'vendor/railsd/actionmailer/lib/'
  dirs << 'vendor/railsd/actionwebservice/README'
  dirs << 'vendor/railsd/actionwebservice/CHANGELOG'
  dirs << 'vendor/railsd/actionwebservice/lib/'
#  dirs << 'vendor/rails/activesupport/README'
  dirs << 'vendor/railsd/activesupport/CHANGELOG'
  dirs << 'vendor/railsd/activesupport/lib/'
  
  RDoc::RDoc.new.document(params + dirs)
end
