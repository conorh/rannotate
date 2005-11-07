require File.dirname(__FILE__) + '/../test_helper'

class RaAttributeTest < Test::Unit::TestCase
  fixtures :ra_attributes

  def setup
    @ra_attribute = RaAttribute.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of RaAttribute,  @ra_attribute
  end
end
