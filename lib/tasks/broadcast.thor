# frozen_string_literal: true

require 'highline/import'

class Broadcast < Thor
  include Thor::Actions

  desc 'version', 'Broadcast Version'
  def version
    require './config/environment'

    AppVersionNotificationWorker.perform_in(10.seconds)
  end
end
