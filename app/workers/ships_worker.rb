class ShipsWorker
  require "ships_loader"
  @queue = (ENV['SHIPS_QUEUE'] || '').to_sym

  def self.perform
    ShipsLoader.run
  end
end
