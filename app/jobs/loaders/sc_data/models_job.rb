# frozen_string_literal: true

module Loaders
  module ScData
    class ModelsJob < ::Loaders::BaseJob
      def perform
        version = ::ScData::Source.version

        import = Imports::ScData::ModelsImport.create(version:)

        import.start!

        loader = ::ScData::Loader::ModelsLoader.new

        loader.all

        import.finish!
      rescue => e
        import.fail!
        import.update!(info: e.message)

        raise e
      end
    end
  end
end
