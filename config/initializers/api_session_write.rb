# frozen_string_literal: true

# Devise's activatable hook signs an inactive user straight back out; required
# here so it runs before this one rather than whenever User is first loaded.
require "devise/hooks/activatable"

# `Api::BaseController` leaves the session unwritten until a user is signed in.
# A user fetched from the session is left to the controller, because Devise's
# timeout check runs on fetch and a timed out session must stay unwritten.
Warden::Manager.after_set_user except: :fetch do |_user, auth, _options|
  session_options = auth.env[Rack::RACK_SESSION_OPTIONS]
  session_options[:skip] = false if session_options&.[](:skip)
end
