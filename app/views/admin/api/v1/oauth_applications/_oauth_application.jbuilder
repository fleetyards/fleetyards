# frozen_string_literal: true

json.cache! ["v1", oauth_application] do
  json.partial!("admin/api/v1/oauth_applications/base", oauth_application:)
end
