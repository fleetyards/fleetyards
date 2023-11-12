# frozen_string_literal: true

module Loaders
  class LocationsJob < ::Loaders::BaseJob
    def perform
      ::Rsi::LocationLoader.new(locations: Starsystem.all.map(&:name)).all
    end
  end
end
