require File.dirname(__FILE__) + '/../test_helper'

class RaSourceCodeTest < Test::Unit::TestCase
  fixtures :ra_source_codes

  def setup
    @ra_source_code = RaSourceCode.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of RaSourceCode,  @ra_source_code
  end
end
