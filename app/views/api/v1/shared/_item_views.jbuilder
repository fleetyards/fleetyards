# frozen_string_literal: true

ItemViews::ATTACHMENT_NAMES.each do |name|
  json.set! name do
    json.partial! "api/v1/shared/file", record:, attr: name
  end
end
