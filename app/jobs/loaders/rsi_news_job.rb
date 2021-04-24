# frozen_string_literal: true

require 'rsi/news_loader'

module Loaders
  class RsiNewsJob < ::Loaders::BaseJob
    def perform
      ::Rsi::NewsLoader.new.update
    end
  end
end
