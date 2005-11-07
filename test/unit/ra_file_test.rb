require File.dirname(__FILE__) + '/../test_helper'

class RaFileTest < Test::Unit::TestCase
  fixtures :ra_files

  def setup
    @ra_file = RaFile.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of RaFile,  @ra_file
  end
end
