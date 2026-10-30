# frozen_string_literal: true

module Loaders
  class CcuCatalogueJob < ::Loaders::BaseJob
    def perform
      ::Rsi::CcuCatalogue.new.run
    end
  end
end
