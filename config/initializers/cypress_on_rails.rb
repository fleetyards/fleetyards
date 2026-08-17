if defined?(CypressOnRails)
  CypressOnRails.configure do |c|
    c.api_prefix = ""
    c.install_folder = File.expand_path("#{__dir__}/../../test/playwright")
    # Test env only: the middleware dispatches arbitrary app commands (incl. a
    # truncating DB clean) at the app root, so a dev server on a port another
    # app's e2e suite targets would wipe the dev database.
    c.use_middleware = Rails.env.test?
    c.logger = Rails.logger
  end
end
