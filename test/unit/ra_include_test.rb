require File.dirname(__FILE__) + '/../test_helper'

class RaIncludeTest < Test::Unit::TestCase
  fixtures :ra_includes

  def setup
    @ra_include = RaInclude.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of RaInclude,  @ra_include
  end
end
