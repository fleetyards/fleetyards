# frozen_string_literal: true

# ActionDispatch::RemoteIp only sets up the lazy address, so this has to run
# directly after it.
Rails.application.config.middleware.insert_after ActionDispatch::RemoteIp, Middleware::RejectSpoofedClientIp
