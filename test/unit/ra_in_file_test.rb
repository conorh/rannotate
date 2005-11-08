require File.dirname(__FILE__) + '/../test_helper'

class RaInFileTest < Test::Unit::TestCase
  fixtures :ra_in_files

  def setup
    @ra_in_file = RaInFile.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of RaInFile,  @ra_in_file
  end
end
