require File.dirname(__FILE__) + '/../test_helper'

class RaRequireTest < Test::Unit::TestCase
  fixtures :ra_requires

  def setup
    @ra_require = RaRequire.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of RaRequire,  @ra_require
  end
end
