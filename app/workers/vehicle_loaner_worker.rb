# frozen_string_literal: true

require 'rsi/loaner_loader'

class VehicleLoanerWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: (ENV['VEHICLE_LOANER_LOADER_QUEUE'] || 'fleetyards_vehicle_loaner_loader').to_sym

  def perform(model_id)
    Vehicle.where(model_id: model_id, loaner: true).destroy_all
    Vehicle.where(model_id: model_id, loaner: false).find_each(&:add_loaners)
  end
end
