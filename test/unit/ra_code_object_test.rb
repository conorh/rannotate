require File.dirname(__FILE__) + '/../test_helper'

class RaCodeObjectTest < Test::Unit::TestCase
  fixtures :ra_code_objects

  def setup
    @ra_code_object = RaCodeObject.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of RaCodeObject,  @ra_code_object
  end
end
