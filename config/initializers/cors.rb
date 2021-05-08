# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors, debug: true, logger: -> { Rails.logger } do
  allow do
    origins [Rails.configuration.app.frontend_endpoint, Rails.configuration.app.admin_endpoint]
    resource '*', headers: :any,
                  methods: %i[get post delete put patch delete options head],
                  expose: %w[Link X-RateLimit-Limit X-RateLimit-Remaining X-RateLimit-Reset],
                  credentials: true,
                  max_age: 0
  end

  allow do
    origins '*'
    resource '*', headers: :any,
                  methods: %i[get options head],
                  expose: %w[Link X-RateLimit-Limit X-RateLimit-Remaining X-RateLimit-Reset],
                  max_age: 0
  end
end
