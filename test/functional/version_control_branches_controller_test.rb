require 'test_helper'

class VersionControlBranchesControllerTest < ActionController::TestCase
  setup do
    @version_control_branch = version_control_branches(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:version_control_branches)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create version_control_branch" do
    assert_difference('VersionControlBranch.count') do
      post :create, version_control_branch: { data_hash: @version_control_branch.data_hash, identity: @version_control_branch.identity, project_status: @version_control_branch.project_status, vcs_branch: @version_control_branch.vcs_branch, version_control_id: @version_control_branch.version_control_id }
    end

    assert_redirected_to version_control_branch_path(assigns(:version_control_branch))
  end

  test "should show version_control_branch" do
    get :show, id: @version_control_branch
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @version_control_branch
    assert_response :success
  end

  test "should update version_control_branch" do
    put :update, id: @version_control_branch, version_control_branch: { data_hash: @version_control_branch.data_hash, identity: @version_control_branch.identity, project_status: @version_control_branch.project_status, vcs_branch: @version_control_branch.vcs_branch, version_control_id: @version_control_branch.version_control_id }
    assert_redirected_to version_control_branch_path(assigns(:version_control_branch))
  end

  test "should destroy version_control_branch" do
    assert_difference('VersionControlBranch.count', -1) do
      delete :destroy, id: @version_control_branch
    end

    assert_redirected_to version_control_branches_path
  end
end
