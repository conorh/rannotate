# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/switchtower.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

require 'rubygems'
require 'rdoc/rdoc'

include Config 

def rdoc_for(section_name, version)
  section = "#{section_name}libdir"
  params = []
  params << "--fmt=yaml"
  params << "--opname=#{section_name}-#{version}"
  dirs = []
  dirs << CONFIG[section]
  RDoc::RDoc.new.document(params + dirs)  
end

task "doc:api:site" do
  rdoc_for('site', RUBY_VERSION)
end

task "doc:api:vendor" do
  rdoc_for('vendor', RUBY_VERSION)
end

task "doc:api:ruby" do
  rdoc_for('ruby', RUBY_VERSION)
end

task "doc:api:rails" do
  rails = "#{Gem.dir}/gems/rails-#{Rails::VERSION::STRING}" 
  activerecord = "#{Gem.dir}/gems/activerecord-#{ActiveRecord::VERSION::STRING}"
  actionpack = "#{Gem.dir}/gems/actionpack-#{ActionPack::VERSION::STRING}"
  actionmailer = "#{Gem.dir}/gems/actionmailer-#{ActionMailer::VERSION::STRING}"
  actionwebservice = "#{Gem.dir}/gems/actionwebservice-#{ActionWebService::VERSION::STRING}"
  activesupport = "#{Gem.dir}/gems/activesupport-#{ActiveSupport::VERSION::STRING}"
  params = []
  params << "--fmt=yaml"
  params << "--opname=rails-#{Rails::VERSION::STRING}"
  dirs = []
  dirs << "#{rails}/README"  
  dirs << "#{rails}/CHANGELOG"
  dirs << "#{rails}/MIT-LICENSE"
  dirs << "#{activerecord}/README" 
  dirs << "#{activerecord}/CHANGELOG"
  dirs << "#{activerecord}/lib/"
  dirs << "#{actionpack}/README"
  dirs << "#{actionpack}/CHANGELOG"
  dirs << "#{actionpack}/lib/"
  dirs << "#{actionmailer}/README"
  dirs << "#{actionmailer}/CHANGELOG"
  dirs << "#{actionmailer}/lib/"
  dirs << "#{actionwebservice}/README"
  dirs << "#{actionwebservice}/CHANGELOG"
  dirs << "#{actionwebservice}/lib/"
#  dirs << "#{activesupport}/README"
  dirs << "#{activesupport}/CHANGELOG"
  dirs << "#{activesupport}/lib/"
  
  RDoc::RDoc.new.document(params + dirs)
end
