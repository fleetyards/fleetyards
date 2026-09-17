# frozen_string_literal: true

module Announcements
  class BaseJob < ::ApplicationJob
    sidekiq_options retry: true, queue: "notifications"
  end
end
