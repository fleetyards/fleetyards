# frozen_string_literal: true

# How a place is drawn: the colour of its circle or glow, and its picture for
# the page header. Admin edits the colour that was set, not the one a star's
# class gives it.
json.color local_assigns.fetch(:curated, false) ? location.color : location.drawn_color
json.unstable location.flare_star?

if location.image.attached?
  json.image do
    json.partial! "api/v1/shared/file", record: location, attr: :image
  end
end
