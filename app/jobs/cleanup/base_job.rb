# frozen_string_literal: true

module Cleanup
  class BaseJob < ::ApplicationJob
    queue_as :cleanup
    sidekiq_options retry: false
  end
end
