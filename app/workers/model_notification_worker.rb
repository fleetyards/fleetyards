# frozen_string_literal: true

require 'discord/new_ship'

class ModelNotificationWorker
  include Sidekiq::Worker
  sidekiq_options retry: true, queue: (ENV['MODEL_NOTIFICATION_QUEUE'] || 'fleetyards_model_notification').to_sym

  def perform(model_id)
    model = Model.find(model_id)
    User.where(sale_notify: true).find_each do |user|
      ModelMailer.notify_new(user.email, model).deliver_later
    end

    Discord::NewShip.new(model: model).run

    model.update(notified: true)
  end
end
