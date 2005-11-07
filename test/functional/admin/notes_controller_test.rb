require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/notes_controller'

# Re-raise errors caught by the controller.
class Admin::NotesController; def rescue_action(e) raise e end; end

class Admin::NotesControllerTest < Test::Unit::TestCase
  def setup
    @controller = Admin::NotesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
  
  def test_filters
  	# test filtering pn 1-2 params
  end
  
  def test_delete
  	# test deleting a few selected
  end
  
end
