# frozen_string_literal: true

require 'rsi/news_loader'

class ScDataShipsWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: (ENV['SC_DATA_SHIPS_QUEUE'] || 'fleetyards_sc_data_ships_loader').to_sym

  def perform
    loader = ::ScData::ShipsLoader.new

    Model.where.not(sc_identifier: nil).find_each do |model|
      loader.load(model)
    end
  end
end
