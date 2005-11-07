require File.dirname(__FILE__) + '/../test_helper'

class RaModuleTest < Test::Unit::TestCase
  fixtures :ra_modules

  def setup
    @ra_module = RaModule.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of RaModule,  @ra_module
  end
end
