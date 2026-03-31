# frozen_string_literal: true

json.array! @applications do |application|
  json.partial!("api/v1/oauth_applications/base", application:)
end
