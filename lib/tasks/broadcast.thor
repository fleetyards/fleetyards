# frozen_string_literal: true

class Broadcast < Thor
  include Thor::Actions

  desc "version", "Broadcast Version"
  def version
    require "./config/environment"
    Notifications::AppVersionJob.perform_in(1.minute)
  end
end
