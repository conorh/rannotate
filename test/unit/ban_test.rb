require File.dirname(__FILE__) + '/../test_helper'

class BanTest < Test::Unit::TestCase
  fixtures :bans

  def setup
    @ban = Ban.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Ban,  @ban
  end
end
