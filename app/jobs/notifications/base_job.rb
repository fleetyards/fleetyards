# frozen_string_literal: true

module Notifications
  class BaseJob < ::ApplicationJob
    queue_as :notifications
    sidekiq_options retry: true
  end
end
