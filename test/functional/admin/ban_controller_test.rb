require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/ban_controller'

# Re-raise errors caught by the controller.
class Admin::BanController; def rescue_action(e) raise e end; end

class Admin::BanControllerTest < Test::Unit::TestCase
  fixtures :bans

  def setup
    @controller = Admin::BanController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.session[:user] = User.new    
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:bans)
  end

  def test_show
    get :show, :id => 1

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:ban)
    assert assigns(:ban).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:ban)
  end

  def test_create
    num_bans = Ban.count

    post :create, :ban => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_bans + 1, Ban.count
  end

  def test_edit
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:ban)
    assert assigns(:ban).valid?
  end

  def test_update
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => 1
  end

  def test_destroy
    assert_not_nil Ban.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Ban.find(1)
    }
  end
end
