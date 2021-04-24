# frozen_string_literal: true

module Loaders
  class BaseJob < ::ApplicationJob
    queue_as :loaders
  end
end
