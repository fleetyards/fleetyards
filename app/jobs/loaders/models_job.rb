# frozen_string_literal: true

module Loaders
  class ModelsJob < ::Loaders::BaseJob
    def perform
      ::Rsi::ModelsLoader.new.all
    end
  end
end
