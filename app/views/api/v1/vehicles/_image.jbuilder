# frozen_string_literal: true

# The ship's picture, wherever it comes from. Omitted where it has none, and the
# client falls back to the stock render.
file = vehicle.display_image
if file.present?
  json.image do
    json.partial! "api/v1/shared/file", record: file.record, attr: file.name
  end
end
