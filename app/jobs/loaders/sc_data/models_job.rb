# frozen_string_literal: true

module Loaders
  module ScData
    class ModelsJob < ::Loaders::BaseJob
      include FetchesParsedTree

      def perform
        version = ::ScData::Source.version

        import = Imports::ScData::ModelsImport.create(version:)

        import.start!

        fetch_parsed_tree!(version)

        loader = ::ScData::Loader::ModelsLoader.new

        loader.all

        import.update!(output: {"ModelsLoader" => loader.stats})

        import.finish!
      rescue => e
        import.fail!
        import.update!(info: e.message)

        raise e
      end
    end
  end
end
