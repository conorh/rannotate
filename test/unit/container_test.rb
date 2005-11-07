require File.dirname(__FILE__) + '/../test_helper'

class ContainerTest < Test::Unit::TestCase
  fixtures :containers

  def setup
    @container = Container.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Container,  @container
  end
end
