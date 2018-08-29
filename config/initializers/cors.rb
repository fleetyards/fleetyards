# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors, debug: true, logger: -> { Rails.logger } do
  allow do
    origins '*'
    resource '*', headers: :any,
                  methods: %i[get post delete put patch delete options head],
                  expose: ['Link', 'X-Renew-JWT', 'X-RateLimit-Limit', 'X-RateLimit-Remaining', 'X-RateLimit-Reset'],
                  max_age: 0
  end
end
