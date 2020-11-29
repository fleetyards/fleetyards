# frozen_string_literal: true

class ScDataShipWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: (ENV['SC_DATA_SHIP_QUEUE'] || 'fleetyards_sc_data_ship_loader').to_sym

  def perform(model_id)
    loader = ::ScData::ShipsLoader.new

    model = Model.find(model_id)

    sc_data = loader.load(model.data_slug)

    model.update(sc_data)
  end
end
