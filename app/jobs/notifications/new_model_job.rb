# frozen_string_literal: true

require 'discord/new_ship'

module Notifications
  class NewModelJob < Notifications::BaseJob
    def perform(model_id)
      model = Model.find(model_id)

      User.confirmed.where(sale_notify: true).find_each do |user|
        ModelMailer.notify_new(user.email, model).deliver_later
      end

      Discord::NewShip.new(model: model).run

      model.update(notified: true)
    end
  end
end
