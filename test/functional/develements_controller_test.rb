require 'test_helper'

class DevelementsControllerTest < ActionController::TestCase
  setup do
    @develement = develements(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:develements)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create develement" do
    assert_difference('Develement.count') do
      post :create, develement: { code: @develement.code, desc: @develement.desc, develement_type_id: @develement.develement_type_id, name: @develement.name, project_id: @develement.project_id, state: @develement.state }
    end

    assert_redirected_to develement_path(assigns(:develement))
  end

  test "should show develement" do
    get :show, id: @develement
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @develement
    assert_response :success
  end

  test "should update develement" do
    put :update, id: @develement, develement: { code: @develement.code, desc: @develement.desc, develement_type_id: @develement.develement_type_id, name: @develement.name, project_id: @develement.project_id, state: @develement.state }
    assert_redirected_to develement_path(assigns(:develement))
  end

  test "should destroy develement" do
    assert_difference('Develement.count', -1) do
      delete :destroy, id: @develement
    end

    assert_redirected_to develements_path
  end
end
