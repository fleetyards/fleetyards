# frozen_string_literal: true

require 'rsi/models_loader'

module Loaders
  class ModelsJob < ::Loaders::BaseJob
    def perform
      ::Rsi::ModelsLoader
        .new(vat_percent: Rails.configuration.rsi.vat_percent)
        .all
    end
  end
end
