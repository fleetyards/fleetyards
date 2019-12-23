# frozen_string_literal: true

require 'rsi/location_loader'

class LocationsWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: (ENV['LOCATION_LOADER_QUEUE'] || 'fleetyards_location_loader').to_sym

  def perform
    ::RSI::LocationLoader.new(locations: Starsystem.all.map(&:name)).all
  end
end
