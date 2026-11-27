# frozen_string_literal: true

json.cache! ["v1", oauth_application] do
  json.partial!("admin/api/v1/oauth_applications/base", oauth_application:)
end
# Tokens are issued and revoked without touching the application, so the
# count would go stale inside the fragment.
json.authorized_users_count oauth_application.authorized_users_count
