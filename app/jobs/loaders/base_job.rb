# frozen_string_literal: true

module Loaders
  class BaseJob < ::ApplicationJob
    queue_as :loaders
    sidekiq_options retry: false
  end
end
