# frozen_string_literal: true

require 'rsi/news_loader'

module Loaders
  class ScDataShipsJob < ::Loaders::BaseJob
    def perform
      loader = ::ScData::ShipsLoader.new

      Model.where.not(sc_identifier: nil).find_each do |model|
        loader.load(model)
      end
    end
  end
end
