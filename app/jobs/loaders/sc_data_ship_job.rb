# frozen_string_literal: true

module Loaders
  class ScDataShipJob < ::Loaders::BaseJob
    def perform(model_id)
      import = Imports::ScDataShipImport.create(input: {model_id: model_id})

      import.start!

      loader = ::ScData::ShipsLoader.new

      loader.load(Model.find(model_id))

      import.finish!
    rescue => e
      import.fail!
      import.update!(info: e.message)

      raise e
    end
  end
end
