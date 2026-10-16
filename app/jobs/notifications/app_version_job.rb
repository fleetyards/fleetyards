# frozen_string_literal: true

module Notifications
  class AppVersionJob < ::Notifications::BaseJob
    def perform
      ActionCable.server.broadcast("app_version", AppVersion.payload)
    end
  end
end
