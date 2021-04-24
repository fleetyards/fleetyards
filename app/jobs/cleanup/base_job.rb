# frozen_string_literal: true

module Cleanup
  class BaseJob < ::ApplicationJob
    queue_as :cleanup
  end
end
