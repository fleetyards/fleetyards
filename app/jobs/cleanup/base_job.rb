# frozen_string_literal: true

module Cleanup
  class BaseJob < ::ApplicationJob
    sidekiq_options queue: 'cleanup'
  end
end
