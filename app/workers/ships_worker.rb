class ShipsWorker
  require "ships_loader"
  @queue = ENV['SHIPS_QUEUE'].to_sym

  def self.perform
    ShipsLoader.run
    state = WorkerState.where(name: "ShipsWorker").first
    state.update(running: false, last_run_end: Time.now)
  end
end
