# frozen_string_literal: true

# The admin edits the store image itself, so only a reader is handed the
# render in its place.
store_image_attr = (local_assigns.fetch(:fallback, false) && record.display_image_attr) || :store_image

json.store_image do
  json.partial! "api/v1/shared/file", record:, attr: store_image_attr
end

if local_assigns.fetch(:extended, false)
  ItemViews::ATTACHMENT_NAMES.each do |name|
    json.set! name do
      json.partial! "api/v1/shared/file", record:, attr: name
    end
  end
end
