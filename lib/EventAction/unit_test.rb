
require 'test/unit'
load 'event_action.rb'

class EventActionStub
  attr_accessor :state, :flag
  extend Antrapol::EventAction

  stateful :initial => :evaluating

  transform :evaluating => :active do
    forward :activate, :guard => Proc.new { |d| d.flag == 1 }
    backward :reevaluating
  end

  transform :active => :kiv do
    forward :kiv
    backward :reactivate
  end

  transform :active => :closed do
    forward :close
  end
end

class TestEventAction < Test::Unit::TestCase
  def test_initial
    stub = EventActionStub.new
    assert_equal(stub.state,"evaluating")
  end

  def test_unsuccessful
    stub = EventActionStub.new
    st = stub.kiv!
    assert_equal(st,false)
    st = stub.close!
    assert_equal(st,false)
  end

  def test_eval_state
    stub = EventActionStub.new
    stub.flag = 1
    stub.activate!
    assert_equal(stub.state,"active")

    stub.reevaluating!
    assert_equal(stub.state,"evaluating")
  end

  def test_activate_state
    stub = EventActionStub.new
    stub.flag = 1
    stub.activate!
    assert_equal(stub.state,"active")

    stub.kiv!
    assert_equal(stub.state,"kiv")
    st = stub.reactivate!
    assert_equal(stub.state,"active")
  end

  def test_close_state
    stub = EventActionStub.new
    stub.flag = 1
    st = stub.activate!
    assert_equal(st,true)
    
    st = stub.close!
    assert_equal(st,true)
    assert_equal(stub.state,"closed")
  end

  def test_condition
    stub = EventActionStub.new
    stub.flag = 0
    st = stub.activate!
    assert_equal(st,false)
    assert_equal(stub.state,"evaluating")
  end
end
