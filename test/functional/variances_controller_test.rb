require 'test_helper'

class VariancesControllerTest < ActionController::TestCase
  setup do
    @variance = variances(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:variances)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create variance" do
    assert_difference('Variance.count') do
      post :create, variance: { created_by: @variance.created_by, desc: @variance.desc, name: @variance.name, project_id: @variance.project_id }
    end

    assert_redirected_to variance_path(assigns(:variance))
  end

  test "should show variance" do
    get :show, id: @variance
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @variance
    assert_response :success
  end

  test "should update variance" do
    put :update, id: @variance, variance: { created_by: @variance.created_by, desc: @variance.desc, name: @variance.name, project_id: @variance.project_id }
    assert_redirected_to variance_path(assigns(:variance))
  end

  test "should destroy variance" do
    assert_difference('Variance.count', -1) do
      delete :destroy, id: @variance
    end

    assert_redirected_to variances_path
  end
end
