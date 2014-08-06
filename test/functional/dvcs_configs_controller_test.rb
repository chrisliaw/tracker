require 'test_helper'

class DvcsConfigsControllerTest < ActionController::TestCase
  setup do
    @dvcs_config = dvcs_configs(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:dvcs_configs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create dvcs_config" do
    assert_difference('DvcsConfig.count') do
      post :create, dvcs_config: { name: @dvcs_config.name, path: @dvcs_config.path }
    end

    assert_redirected_to dvcs_config_path(assigns(:dvcs_config))
  end

  test "should show dvcs_config" do
    get :show, id: @dvcs_config
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @dvcs_config
    assert_response :success
  end

  test "should update dvcs_config" do
    put :update, id: @dvcs_config, dvcs_config: { name: @dvcs_config.name, path: @dvcs_config.path }
    assert_redirected_to dvcs_config_path(assigns(:dvcs_config))
  end

  test "should destroy dvcs_config" do
    assert_difference('DvcsConfig.count', -1) do
      delete :destroy, id: @dvcs_config
    end

    assert_redirected_to dvcs_configs_path
  end
end
