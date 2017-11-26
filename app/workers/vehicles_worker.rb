# frozen_string_literal: true

class VehiclesWorker
  include Sidekiq::Worker
  sidekiq_options retry: true, queue: (ENV['VEHICLES_QUEUE'] || 'fleetyards_vehicles_loader').to_sym

  def perform(model_id)
    Vehicle.where(model_id: model_id, sale_notify: true).find_each do |vehicle|
      next unless vehicle.user.sale_notify?
      next unless vehicle.user.email == 'mortik@fleetyards.net'

      ActionCable.server.broadcast("on_sale_#{vehicle.user.username}", vehicle.to_builder.target!)
      VehicleMailer.on_sale(vehicle).deliver_later
    end
  end
end
