# frozen_string_literal: true

require 'rsi/location_loader'

module Loaders
  class LocationsJob < ::Loaders::BaseJob
    def perform
      ::Rsi::LocationLoader.new(locations: Starsystem.all.map(&:name)).all
    end
  end
end
