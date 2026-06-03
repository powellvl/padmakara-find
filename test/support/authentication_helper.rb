module AuthenticationHelper
  # Signs in by POSTing to the real session endpoint so the signed cookie
  # is set exactly as the application sets it in production code.
  # Requires the user factory to have password "password123".
  def sign_in(user)
    post session_path, params: { email: user.email, password: "password123" }
  end
end

class ActionDispatch::IntegrationTest
  include AuthenticationHelper
end
