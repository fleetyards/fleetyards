# frozen_string_literal: true

# `Api::BaseController` leaves the session unwritten until a user is signed in.
# A sign-in can happen anywhere in the request -- a password in
# `SessionsController#create`, a remember-me cookie in whichever callback first
# asks for the user -- so it is caught here rather than at a fixed point in the
# callback chain. A user fetched from the session is left to the controller:
# Devise's timeout check runs on fetch, after this hook, and a timed out session
# must stay unwritten.
Warden::Manager.after_set_user except: :fetch do |_user, auth, _options|
  session_options = auth.env[Rack::RACK_SESSION_OPTIONS]
  session_options[:skip] = false if session_options&.[](:skip)
end
