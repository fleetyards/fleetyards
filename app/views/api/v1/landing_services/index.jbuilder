# frozen_string_literal: true

json.array! @landing_services do |landing_service|
  json.key landing_service.key
  if landing_service.icon.attached?
    json.icon do
      json.partial! "api/v1/shared/file", record: landing_service, attr: :icon
    end
  end
end
