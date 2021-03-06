require 'test_helper'

class IssueTypesControllerTest < ActionController::TestCase
  setup do
    @issue_type = issue_types(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:issue_types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create issue_type" do
    assert_difference('IssueType.count') do
      post :create, issue_type: { desc: @issue_type.desc, name: @issue_type.name, state: @issue_type.state }
    end

    assert_redirected_to issue_type_path(assigns(:issue_type))
  end

  test "should show issue_type" do
    get :show, id: @issue_type
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @issue_type
    assert_response :success
  end

  test "should update issue_type" do
    put :update, id: @issue_type, issue_type: { desc: @issue_type.desc, name: @issue_type.name, state: @issue_type.state }
    assert_redirected_to issue_type_path(assigns(:issue_type))
  end

  test "should destroy issue_type" do
    assert_difference('IssueType.count', -1) do
      delete :destroy, id: @issue_type
    end

    assert_redirected_to issue_types_path
  end
end
