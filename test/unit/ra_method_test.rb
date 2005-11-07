require File.dirname(__FILE__) + '/../test_helper'

class RaMethodTest < Test::Unit::TestCase
  fixtures :ra_methods

  def setup
    @ra_method = RaMethod.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of RaMethod,  @ra_method
  end
end
