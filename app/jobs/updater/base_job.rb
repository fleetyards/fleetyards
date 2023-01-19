# frozen_string_literal: true

module Updater
  class BaseJob < ::ApplicationJob
    sidekiq_options queue: 'updater'
  end
end
