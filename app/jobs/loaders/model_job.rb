# frozen_string_literal: true

module Loaders
  class ModelJob < ::Loaders::BaseJob
    def perform(model_id)
      model = Model.find(model_id)
      import = Imports::ModelImport.create(input: {model_id: model.id, rsi_id: model.rsi_id})

      import.start!

      if ::Rsi::ModelsLoader.new.one_for(model) == false
        import.fail!
        import.update!(info: "No ship matrix entry matches #{model.name}")
        return
      end

      import.finish!
    rescue => e
      import.fail!
      import.update!(info: e.message)

      raise e
    end
  end
end
