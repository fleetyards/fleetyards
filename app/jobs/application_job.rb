# frozen_string_literal: true

class ApplicationJob
  include Sidekiq::Worker

  sidekiq_options retry: false
end
