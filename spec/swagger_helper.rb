# frozen_string_literal: true

require "rails_helper"

require "rswag/specs"
require "rswag/specs/railtie" if defined?(Rails::Railtie)
require_relative "./rswag/request_factory_monkey_patch"

RSpec.configure do |config|
  config.swagger_root = Rails.root.join("api").to_s

  config.swagger_docs = Rails.configuration.api

  config.swagger_format = :yaml
end
