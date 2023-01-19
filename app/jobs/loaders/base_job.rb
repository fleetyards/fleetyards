# frozen_string_literal: true

module Loaders
  class BaseJob < ::ApplicationJob
    sidekiq_options queue: 'loaders'
  end
end
