require File.dirname(__FILE__) + '/../test_helper'
require 'notes_controller'

# Re-raise errors caught by the controller.
class NotesController; def rescue_action(e) raise e end; end

class NotesControllerTest < Test::Unit::TestCase
  fixtures :notes

  def setup
    @controller = NotesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_list_notes
  	paramsGet = {:category => 'class', :name => 'ActionController::Test', :return_url => 'http://www.test.com#something' }   
  	# Test display list of notes and subnotes
  	get :list, paramsGet
  	assert_equal 2, assigns(:notes).length
  	assert_equal 2, assigns(:subnote)[:count]	
  	assert_equal 'Methods', assigns(:subnote)[:type]
  	assert_equal paramsGet[:category], assigns(:category)
  	assert_equal paramsGet[:name], assigns(:name)  	    	
  	assert_equal paramsGet[:return_url], assigns(:content_url)
  	assert_template 'list'
	end

	def test_list_no_notes
  	paramsGet = {:category => 'class', :name => 'Action', :return_url => 'http://www.test.com#something' } 
  	get :list, paramsGet
  	assert_equal 0, assigns(:notes).length
  	assert_equal 0, assigns(:subnote)[:count]
  	assert_equal paramsGet[:category], assigns(:category)
  	assert_equal paramsGet[:name], assigns(:name)  	    	
  	assert_equal paramsGet[:return_url], assigns(:content_url)
  	assert_template 'list'
	end

	def test_list_methods
  	paramsGet = {:category => 'method', :name => 'ActionController::Test.index', :return_url => 'http://www.test.com#something' } 
  	get :list, paramsGet
  	assert_equal 3, assigns(:notes).length
  	assert_nil assigns(:subnote)
  	assert_equal paramsGet[:category], assigns(:category)
  	assert_equal paramsGet[:name], assigns(:name)  	    	
  	assert_equal paramsGet[:return_url], assigns(:content_url)
  	assert_template 'list'  	
  end
  
  def test_overview_2_methods
  	paramsGet = {:category => 'method', :name => 'ActionController::Test', :return_url => 'http://www.test.com#something' } 
  	get :overview, paramsGet
  	assert_equal 2, assigns(:notes).length
  	assert_equal paramsGet[:category], assigns(:category)
  	assert_equal paramsGet[:name], assigns(:name)  	
  	assert_equal paramsGet[:return_url], assigns(:content_url)
  	assert_template 'overview'   	
  end
  
  def test_overview_no_methods
  	paramsGet = {:category => 'method', :name => 'somefile/something.rb', :return_url => 'http://www.test.com#something' } 
  	get :overview, paramsGet
  	assert_equal 0, assigns(:notes).length
  	assert_equal paramsGet[:category], assigns(:category)
  	assert_equal paramsGet[:name], assigns(:name)  	
  	assert_equal paramsGet[:return_url], assigns(:content_url)
  	assert_template 'overview'   	
  end
  
  def test_new
  	paramsPost = {:category => 'method', :name => 'ActionController::Test.index', :content_url => 'http://www.test.com#something'}
  	post :new, paramsPost
  	assert_kind_of Note, assigns(:note)
  	assert_equal paramsPost[:category], assigns(:note)[:category]
  	assert_equal paramsPost[:name], assigns(:note)[:name]
  	assert_equal paramsPost[:content_url], assigns(:note).content_url
  	assert_template 'new'
  end

	def test_preview		
  	paramsPost = { :note => {:category => 'method', :name => 'ActionController::Test.index', :content_url => 'http://www.test.com#something',
  		:text => "asdfasdfasdfasdfasdfasdf\r\n\n\nasdfasdfasdf<ruby>do some ruby</ruby><ruby>", :email=>"somedude@asdfasd.com"}}
  	post :preview, paramsPost
  	assert_kind_of Note, assigns(:note)
  	assert_equal paramsPost[:note][:category], assigns(:note)[:category]
  	assert_equal paramsPost[:note][:text], assigns(:note)[:text]
  	assert_equal paramsPost[:note][:name], assigns(:note)[:name]
  	assert_equal paramsPost[:note][:email], assigns(:note)[:email]
  	assert_equal paramsPost[:note][:content_url], assigns(:note).content_url
  	assert_template 'preview'
 	end

  def test_create
  	# TODO: Test create note with no IP
  	# TODO: Test create two notes too quickly
  	# TODO: Test with note on ban list  

		count = Note.count
  	
  	paramsPost = { :create => "create", :note => {:category => 'method', :name => 'ActionController::Test.index', :content_url => 'http://www.test.com#something',
  		:text => "asdfasdfasdfasdfasdfasdf\r\n\n\nasdfasdfasdf<ruby>do some ruby</ruby><ruby>", :email=>"somedude@asdfasd.com"}}
  	post :preview, paramsPost
  	assert_template 'success'
  	assert_equal count+1, Note.count  
  	
  end

end
