# frozen_string_literal: true

class Broadcast < Thor
  include Thor::Actions
  desc "version", "Broadcast Version"
  def version
    require "./config/environment"
    Notifications::AppVersionJob.perform_in(1.minute)
  end

  desc "check_sc_data", "Check for new SC Data Version"
  def check_sc_data
    require "./config/environment"
    ScDataCheckJob.perform_in(5.minutes)
  end
end
