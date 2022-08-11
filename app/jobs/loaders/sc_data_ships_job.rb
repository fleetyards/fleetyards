# frozen_string_literal: true

require 'rsi/news_loader'

module Loaders
  class ScDataShipsJob < ::Loaders::BaseJob
    def perform(version:)
      import = Imports::ScDataImport.create(version: version)

      import.start!

      loader = ::ScData::ShipsLoader.new

      Model.where.not(sc_identifier: nil).find_each do |model|
        loader.load(model)
      end

      import.finish!
    rescue StandardError => e
      import.fail!
      import.update!(info: e.message)

      raise e
    end
  end
end
