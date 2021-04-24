# frozen_string_literal: true

module Loaders
  class ScDataShipJob < ::Loaders::BaseJob
    def perform(model_id)
      loader = ::ScData::ShipsLoader.new

      loader.load(Model.find(model_id))
    end
  end
end
