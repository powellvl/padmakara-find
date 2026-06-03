module AuthenticationHelper
  def sign_in(user)
    session_record = Session.create!(user: user, ip_address: "127.0.0.1", user_agent: "Test")
    cookies.signed[:session_id] = session_record.id
  end
end

class ActionDispatch::IntegrationTest
  include AuthenticationHelper
end
