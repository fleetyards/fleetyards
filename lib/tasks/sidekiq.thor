# frozen_string_literal: true

require 'thor'

class Sidekiq < Thor
  include Thor::Actions

  desc 'clear', 'Clear Sidekiq Queues'
  def clear
    require './config/environment'
    require 'sidekiq/api'

    ::Sidekiq::Queue.all.each(&:clear)
    ::Sidekiq::RetrySet.new.clear
    ::Sidekiq::ScheduledSet.new.clear
    ::Sidekiq::DeadSet.new.clear
  end
end
