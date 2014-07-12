require 'test_helper'

class DevelementTypesControllerTest < ActionController::TestCase
  setup do
    @develement_type = develement_types(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:develement_types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create develement_type" do
    assert_difference('DevelementType.count') do
      post :create, develement_type: { desc: @develement_type.desc, name: @develement_type.name, state: @develement_type.state }
    end

    assert_redirected_to develement_type_path(assigns(:develement_type))
  end

  test "should show develement_type" do
    get :show, id: @develement_type
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @develement_type
    assert_response :success
  end

  test "should update develement_type" do
    put :update, id: @develement_type, develement_type: { desc: @develement_type.desc, name: @develement_type.name, state: @develement_type.state }
    assert_redirected_to develement_type_path(assigns(:develement_type))
  end

  test "should destroy develement_type" do
    assert_difference('DevelementType.count', -1) do
      delete :destroy, id: @develement_type
    end

    assert_redirected_to develement_types_path
  end
end
