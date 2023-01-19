# frozen_string_literal: true

module Notifications
  class BaseJob < ::ApplicationJob
    sidekiq_options retry: true, queue: "notifications"
  end
end
