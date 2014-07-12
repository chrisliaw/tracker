require 'test_helper'

class VersionControlsControllerTest < ActionController::TestCase
  setup do
    @version_control = version_controls(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:version_controls)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create version_control" do
    assert_difference('VersionControl.count') do
      post :create, version_control: { created_by: @version_control.created_by, name: @version_control.name, updated_by: @version_control.updated_by, upstream_vcs_class: @version_control.upstream_vcs_class, upstream_vcs_path: @version_control.upstream_vcs_path, vcs_class: @version_control.vcs_class, vcs_path: @version_control.vcs_path, versionable_id: @version_control.versionable_id, versionable_type: @version_control.versionable_type }
    end

    assert_redirected_to version_control_path(assigns(:version_control))
  end

  test "should show version_control" do
    get :show, id: @version_control
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @version_control
    assert_response :success
  end

  test "should update version_control" do
    put :update, id: @version_control, version_control: { created_by: @version_control.created_by, name: @version_control.name, updated_by: @version_control.updated_by, upstream_vcs_class: @version_control.upstream_vcs_class, upstream_vcs_path: @version_control.upstream_vcs_path, vcs_class: @version_control.vcs_class, vcs_path: @version_control.vcs_path, versionable_id: @version_control.versionable_id, versionable_type: @version_control.versionable_type }
    assert_redirected_to version_control_path(assigns(:version_control))
  end

  test "should destroy version_control" do
    assert_difference('VersionControl.count', -1) do
      delete :destroy, id: @version_control
    end

    assert_redirected_to version_controls_path
  end
end
