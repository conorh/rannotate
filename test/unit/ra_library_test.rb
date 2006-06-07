require File.dirname(__FILE__) + '/../test_helper'

class RaLibraryTest < Test::Unit::TestCase
  fixtures :ra_libraries

  # Replace this with your real tests.
  def test_truth
    assert_kind_of RaLibrary, ra_libraries(:first)
  end
end
