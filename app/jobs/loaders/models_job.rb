# frozen_string_literal: true

module Loaders
  class ModelsJob < ::Loaders::BaseJob
    def perform
      ::Rsi::ModelsLoader
        .new(vat_percent: Rails.configuration.rsi.vat_percent)
        .all
    end
  end
end
