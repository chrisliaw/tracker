require 'test_helper'

class EventActionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test "state changes" do
    p = Project.new
    assert_equal(p.state,"evaluation")

    p.activate!
    assert_equal(p.state,"active")
    p.reevaluate!
    assert_equal(p.state,"evaluation")

    assert_raise(NoMethodError) {
      p.kiv!
    }

    p.activate!
    assert_equal(p.state,"active")
    p.on_hold!
    assert_equal(p.state,"kiv")
    p.reactivate!
    assert_equal(p.state,"active")

    p.reevaluate!
    assert_equal(p.state,"evaluation")
    p.on_hold!
    assert_equal(p.state,"kiv")
    p.reevaluate!
    assert_equal(p.state,"evaluation")

    p.activate!
    assert_equal(p.state,"active")
    p.EOL!
    assert_equal(p.state,"end_of_life")
    p.reactivate!
    assert_equal(p.state,"active")

    p.EOL!
    assert_equal(p.state,"end_of_life")
    p.archive!
    assert_equal(p.state,"archived")

  end 
end
