# frozen_string_literal: true

if entry.blank? || entry.display_image.blank?
  json.null!
elsif entry.image.attached?
  json.partial! "api/v1/shared/file", record: entry, attr: :image
else
  json.partial! "api/v1/shared/file", record: entry.item, attr: :store_image
end
