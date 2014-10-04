require "ships_loader"

class ShipsWorker
  include Sidekiq::Worker
  sidekiq_options queue: (ENV['SHIP_LOADER_QUEUE'] || 'fleetyards_ship_loader').to_sym

  def perform
    ShipsLoader.new.run
  end
end
