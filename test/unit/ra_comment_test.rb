require File.dirname(__FILE__) + '/../test_helper'

class RaCommentTest < Test::Unit::TestCase
  fixtures :ra_comments

  def setup
    @ra_comment = RaComment.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of RaComment,  @ra_comment
  end
end
