require File.dirname(__FILE__) + '/../test_helper'

class RaClassTest < Test::Unit::TestCase
  fixtures :ra_classes

  def setup
    @ra_class = RaClass.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of RaClass,  @ra_class
  end
end
