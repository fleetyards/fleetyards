# frozen_string_literal: true

module Updater
  class BaseJob < ::ApplicationJob
    queue_as :updater
  end
end
