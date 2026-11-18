# frozen_string_literal: true

# OmniAuth builds the redirect_uri it sends to providers from the Host or
# X-Forwarded-Host header. Sign-ins only start on the frontend host, so any
# other host is refused. Development and test serve under arbitrary hosts.
unless Rails.env.local?
  OmniAuth.config.allowed_hosts = [URI(FRONTEND_ENDPOINT).host]
end
