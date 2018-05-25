# frozen_string_literal: true

class ModelNotificationWorker
  include Sidekiq::Worker
  sidekiq_options retry: true, queue: (ENV['MODEL_NOTIFICATION_QUEUE'] || 'fleetyards_model_notification').to_sym

  def perform(model_id)
    model = Model.find(model_id)
    User.where(sale_notify: true).find_each do |user|
      ModelMailer.notify_new(user.email, model).deliver_later
    end
  end
end
