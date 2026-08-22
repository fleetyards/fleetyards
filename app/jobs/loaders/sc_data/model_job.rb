# frozen_string_literal: true

module Loaders
  module ScData
    class ModelJob < ::Loaders::BaseJob
      include FetchesParsedTree

      def perform(model_id)
        import = Imports::ScData::ModelImport.create(input: {model_id: model_id})

        import.start!

        fetch_parsed_tree!

        loader = ::ScData::Loader::ModelsLoader.new

        loader.one(Model.find(model_id))

        import.finish!
      rescue => e
        import.fail!
        import.update!(info: e.message)

        raise e
      end
    end
  end
end
