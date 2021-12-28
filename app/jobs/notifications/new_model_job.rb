# frozen_string_literal: true

require 'discord/new_ship'

module Notifications
  class NewModelJob < Notifications::BaseJob
    def perform(model_id)
      model = Model.find(model_id)

      Discord::NewShip.new(model: model).run

      model.update(notified: true)
    end
  end
end
