require "ships_loader"

class ShipWorker
  include Sidekiq::Worker
  sidekiq_options queue: (ENV['SHIP_LOADER_QUEUE'] || 'fleetyards_ship_loader').to_sym

  def perform(ship_name)
    ShipsLoader.new.one(ship_name)
  end
end
