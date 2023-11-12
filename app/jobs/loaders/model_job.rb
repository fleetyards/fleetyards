# frozen_string_literal: true

module Loaders
  class ModelJob < ::Loaders::BaseJob
    def perform(rsi_id)
      ::Rsi::ModelsLoader
        .new(vat_percent: Rails.configuration.rsi.vat_percent)
        .one(rsi_id)
    end
  end
end
