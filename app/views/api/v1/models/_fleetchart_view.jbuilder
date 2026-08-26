# frozen_string_literal: true

# The ship views a fleetchart draws with, keyed by slug so a caller can match them
# against a list it already holds.
#
# Every view is named here, including the `extended_` ones the list tier never
# carried -- the panzoom chart reaches for those and has been finding nothing.

json.slug model.slug

json.media do
  %i[
    angled_view angled_view_colored front_view front_view_colored
    side_view side_view_colored top_view top_view_colored
    extended_angled_view extended_angled_view_colored
    extended_front_view extended_front_view_colored
    extended_side_view extended_side_view_colored
    extended_top_view extended_top_view_colored
  ].each do |view|
    json.set! view do
      json.partial! "api/v1/shared/file", record: model, attr: view
    end
  end
end
