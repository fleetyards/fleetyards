# frozen_string_literal: true

json.store_image do
  json.partial! "api/v1/shared/file", record:, attr: :store_image
end

if local_assigns.fetch(:extended, false)
  ItemViews::ATTACHMENT_NAMES.each do |name|
    json.set! name do
      json.partial! "api/v1/shared/file", record:, attr: name
    end
  end
end
