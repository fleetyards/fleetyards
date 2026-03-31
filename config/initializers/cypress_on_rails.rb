if defined?(CypressOnRails)
  CypressOnRails.configure do |c|
    c.api_prefix = ""
    c.install_folder = File.expand_path("#{__dir__}/../../spec/playwright")
    c.use_middleware = !Rails.env.production?
    c.logger = Rails.logger
  end
end
