require File.dirname(__FILE__) + '/../test_helper'

class NoteTest < Test::Unit::TestCase
  fixtures :notes

  def setup
    @note = Note.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Note,  @note
  end
  
  def test_validations
    # Test no IP address
    # Test text too short
    # Test text too long
    # Test no name
    # Test no category
    # Test email too long
    # Test email too short   
  end

  def test_create
  end  
  
  def test_updating
  end
  
  def test_delete
  	# delete one note
  	# delete multiple notes
  end
  
  def test_list
  
  end
  
end
