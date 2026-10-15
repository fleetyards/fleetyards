# frozen_string_literal: true

# The ship's picture, wherever it comes from. Omitted where it has none, and the
# client falls back to the stock render.
record, attr = vehicle.image_source
if record.present?
  json.image do
    json.partial! "api/v1/shared/file", record:, attr:
  end
end
