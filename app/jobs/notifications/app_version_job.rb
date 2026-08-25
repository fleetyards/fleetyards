# frozen_string_literal: true

module Notifications
  class AppVersionJob < ::Notifications::BaseJob
    def perform
      ActionCable.server.broadcast("app_version", {
        version: Fleetyards::VERSION,
        codename: Fleetyards::CODENAME
      })
    end
  end
end
