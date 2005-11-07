require File.dirname(__FILE__) + '/../test_helper'
require 'account_controller'

# Set salt to 'change-me' because thats what the fixtures assume. 
User.salt = 'change-me'

# Raise errors beyond the default web-based presentation
class AccountController; def rescue_action(e) raise e end; end

class AccountControllerTest < Test::Unit::TestCase
  
  fixtures :users
  
  def setup
    @controller = AccountController.new
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
    @request.host = "localhost"
    @bob = User.find(1000001)  	      
  end
  
  def test_auth_bob
    @request.session[:return_to] = "/bogus/location"

    post :login, :user_login => "bob", :user_password => "test"
    assert_not_nil(@response.session[:user])

    assert_equal @bob, @response.session[:user]
    
    assert_redirect_url "http://localhost/bogus/location"
  end
  
  def test_signup
    @request.session[:return_to] = "/bogus/location"

		# test signing up with nobody in the session
    post :signup, :user => { :login => "newbob", :password => "newpassword", :password_confirmation => "newpassword" }
    assert_nil(@response.session[:user])


		# test signing up with someone in the session
    @request.session[:return_to] = "/bogus/location"
		@request.session[:user] = true
    post :signup, :user => { :login => "newbob", :password => "newpassword", :password_confirmation => "newpassword" }
    assert_not_nil(@response.session[:user])
    
    assert_redirect_url "http://localhost/bogus/location"
  end

  def test_bad_signup
    @request.session[:return_to] = "/bogus/location"

    post :signup, :user => { :login => "newbob", :password => "newpassword", :password_confirmation => "wrong" }
    assert_nil(@response.session[:user])
    
    post :signup, :user => { :login => "yo", :password => "newpassword", :password_confirmation => "newpassword" }
    assert_nil(@response.session[:user])

    post :signup, :user => { :login => "yo", :password => "newpassword", :password_confirmation => "wrong" }
    assert_nil(@response.session[:user])
  end

  def test_invalid_login
    post :login, :user_login => "bob", :user_password => "not_correct"
     
    assert_nil(@response.session[:user])
    
    assert_template_has "login"
  end
  
  def test_login_logoff

    post :login, :user_login => "bob", :user_password => "test"
    assert_not_nil(@response.session[:user])

    get :logout
    assert_nil(@response.session[:user])

  end
  
end
