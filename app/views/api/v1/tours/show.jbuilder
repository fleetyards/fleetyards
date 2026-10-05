# frozen_string_literal: true

json.partial! "api/v1/tours/tour", tour: @tour

# Only on a single tour: it costs two queries, and only the tour's own page
# offers deleting it.
json.deletable @tour.deletable?
