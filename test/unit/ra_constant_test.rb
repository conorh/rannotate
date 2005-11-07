require File.dirname(__FILE__) + '/../test_helper'

class RaConstantTest < Test::Unit::TestCase
  fixtures :ra_constants

  def setup
    @ra_constant = RaConstant.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of RaConstant,  @ra_constant
  end
end
