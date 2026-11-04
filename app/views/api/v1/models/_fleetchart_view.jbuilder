# frozen_string_literal: true

# The ship views a fleetchart draws with, keyed by slug so a caller can match them
# against a list it already holds.
#
json.slug model.slug

json.media do
  Model::FLEETCHART_VIEW_ATTACHMENT_NAMES.each do |view|
    json.set! view do
      json.partial! "api/v1/shared/file", record: model, attr: view
    end
  end
end
