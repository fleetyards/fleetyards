# frozen_string_literal: true

# How a body is drawn: its picture where one was uploaded, its colour where
# not. Left out when neither is set, and the page falls back to its own.
json.color location.color
json.unstable location.flare_star?

if location.image.attached?
  json.image do
    json.partial! "api/v1/shared/file", record: location, attr: :image
  end
end
