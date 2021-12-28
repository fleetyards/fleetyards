# frozen_string_literal: true

module Notifications
  class AdminJob < ::Notifications::BaseJob
    def perform
      stats = {
        registrations: User.where(created_at: (1.week.ago)..Time.zone.now).size,
        ships: Model.where(created_at: (1.week.ago)..Time.zone.now).size,
        vehicles: Vehicle.where(created_at: (1.week.ago)..Time.zone.now).size,
        fleets: Fleet.where(created_at: (1.week.ago)..Time.zone.now).size
      }

      AdminMailer.weekly(stats).deliver_later
    end
  end
end
