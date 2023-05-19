# frozen_string_literal: true

require "rails_helper"

require "rswag/specs"
require "rswag/specs/railtie" if defined?(Rails::Railtie)
require_relative "./rswag/request_factory_monkey_patch"

RSpec.configure do |config|
  config.swagger_root = Rails.root.join(Rails.configuration.api_schema.folder).to_s

  config.swagger_docs = Rails.configuration.api_schema.schemas

  config.swagger_format = :yaml
end
