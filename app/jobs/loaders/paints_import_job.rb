# frozen_string_literal: true

require 'rsi/paints_loader'

module Loaders
  class PaintsImportJob < ::Loaders::BaseJob
    def perform(paints_data)
      ::Rsi::PaintsLoader.new.import(paints_data)
    end
  end
end
