# frozen_string_literal: true

module Loaders
  class RsiNewsJob < ::Loaders::BaseJob
    def perform
      ::Rsi::NewsLoader.new.update
    end
  end
end
