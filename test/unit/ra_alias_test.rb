require File.dirname(__FILE__) + '/../test_helper'

class RaAliasTest < Test::Unit::TestCase
  fixtures :ra_aliases

  def setup
    @ra_alias = RaAlias.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of RaAlias,  @ra_alias
  end
end
