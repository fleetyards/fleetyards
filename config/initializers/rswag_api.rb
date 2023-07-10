# frozen_string_literal: true

Rswag::Api.configure do |config|
  config.swagger_root = Rails.root.join(Rails.configuration.api_schema.folder)
end
