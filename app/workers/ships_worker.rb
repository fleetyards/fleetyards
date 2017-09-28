# frozen_string_literal: true

require "ships_loader"

class ShipsWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: (ENV['SHIP_LOADER_QUEUE'] || 'fleetyards_ship_loader').to_sym

  def perform
    ShipsLoader
      .new(vat_percent: Rails.application.secrets[:rsi_vat_percent])
      .all
  end
end
