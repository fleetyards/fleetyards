# frozen_string_literal: true

class Broadcast < Thor
  include Thor::Actions
  desc 'version', 'Broadcast Version'
  def version
    require './config/environment'
    Notifications::AppVersionJob.set(wait: 1.minute).perform_later
  end

  desc 'check_sc_data', 'Check for new SC Data Version'
  def check_sc_data
    require './config/environment'
    ScDataCheckJob.set(wait: 5.minutes).perform_later
  end
end
