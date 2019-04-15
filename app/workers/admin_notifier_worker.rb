# frozen_string_literal: true

class AdminNotifierWorker
  include Sidekiq::Worker
  sidekiq_options retry: true, queue: (ENV['ADMIN_NOTIFIER_QUEUE'] || 'fleetyards_admin_notifier').to_sym

  def perform
    stats = {
      registrations: User.where(created_at: (Time.zone.now - 1.week)..Time.zone.now).size,
      ships: Model.where(created_at: (Time.zone.now - 1.week)..Time.zone.now).size,
      vehicles: Vehicle.where(created_at: (Time.zone.now - 1.week)..Time.zone.now).size,
      fleets: Fleet.where(created_at: (Time.zone.now - 1.week)..Time.zone.now).size
    }

    AdminMailer.weekly(stats).deliver_later
  end
end
