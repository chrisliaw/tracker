require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test "duplicate login" do
    u = User.new
    u.login = 'jack'
    u.save
    assert_equal u.errors.full_messages,["Login has already been taken"]
  end

  test "empty login" do
    u = User.new
    u.save
    assert_equal u.errors.full_messages,["Login can't be blank"]
  end
end
