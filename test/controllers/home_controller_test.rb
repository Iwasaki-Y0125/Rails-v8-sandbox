require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "redirects to login when not signed in" do
    get root_url
    assert_redirected_to new_session_path
  end
end
