# frozen_string_literal: true

require 'rsi/news_loader'

class ScDataShipsWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: (ENV['SC_DATA_SHIPS_QUEUE'] || 'fleetyards_sc_data_ships_loader').to_sym

  def perform
    loader = ::ScData::ShipsLoader.new

    Model.where.not(data_slug: nil).find_each do |model|
      sc_data = loader.load(model.data_slug)
      model.update(sc_data)
    end
  end
end
