require File.dirname(__FILE__) + '/../test_helper'

class RaContainerTest < Test::Unit::TestCase
  fixtures :ra_containers

  def setup
    @ra_container = RaContainer.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of RaContainer,  @ra_container
  end
end
