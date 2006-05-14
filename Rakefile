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
  dirs << 'vendor/rails/railties/README'  
  dirs << 'vendor/rails/railties/CHANGELOG'
  dirs << 'vendor/rails/railties/MIT-LICENSE'
  dirs << 'vendor/rails/activerecord/README' 
  dirs << 'vendor/rails/activerecord/CHANGELOG'
  dirs << 'vendor/rails/activerecord/lib/'
  dirs << 'vendor/rails/actionpack/README'
  dirs << 'vendor/rails/actionpack/CHANGELOG'
  dirs << 'vendor/rails/actionpack/lib/'
  dirs << 'vendor/rails/actionmailer/README'
  dirs << 'vendor/rails/actionmailer/CHANGELOG'
  dirs << 'vendor/rails/actionmailer/lib/'
  dirs << 'vendor/rails/actionwebservice/README'
  dirs << 'vendor/rails/actionwebservice/CHANGELOG'
  dirs << 'vendor/rails/actionwebservice/lib/'
#  dirs << 'vendor/rails/activesupport/README'
  dirs << 'vendor/rails/activesupport/CHANGELOG'
  dirs << 'vendor/rails/activesupport/lib/'
  
  RDoc::RDoc.new.document(params + dirs)
end
