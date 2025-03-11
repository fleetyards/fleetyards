# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors, debug: Rails.env.development?, logger: -> { Rails.logger } do
  allow do
    origins ["localhost:#{ENV["PORT"]}", FRONTEND_ENDPOINT, ADMIN_ENDPOINT, API_ENDPOINT, "https://robertsspaceindustries.com"]
    resource "*", headers: :any,
      methods: %i[get post delete put patch options head],
      expose: %w[Link X-RateLimit-Limit X-RateLimit-Remaining X-RateLimit-Reset],
      credentials: true,
      max_age: 0
  end

  allow do
    origins "*"
    resource "*", headers: :any,
      methods: %i[get options head],
      expose: %w[Link X-RateLimit-Limit X-RateLimit-Remaining X-RateLimit-Reset],
      max_age: 0
  end
end
