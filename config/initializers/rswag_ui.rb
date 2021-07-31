# frozen_string_literal: true

Rswag::Ui.configure do |config|
  config.swagger_endpoint '/schema/v1.json', 'API V1 Docs'
  config.swagger_endpoint '/schema/admin-v1.json', 'ADMIN API V1 Docs'

  # Add Basic Auth in case your API is private
  # c.basic_auth_enabled = true
  # c.basic_auth_credentials 'username', 'password'
end
