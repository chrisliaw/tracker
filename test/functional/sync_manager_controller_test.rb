require 'test_helper'

class SyncManagerControllerTest < ActionController::TestCase
  test "should get login" do
    get :login
    assert_response :success
  end

  test "should get sync" do
    get :sync
    assert_response :success
  end

end
