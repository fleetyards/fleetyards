# frozen_string_literal: true

# Rack::MethodOverride is the first middleware to parse the form body, so the
# check has to run directly before it.
Rails.application.config.middleware.insert_before Rack::MethodOverride, Middleware::RejectMalformedFormBody
