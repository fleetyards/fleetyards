# frozen_string_literal: true

class Broadcast < Thor
  include Thor::Actions
  desc 'version', 'Broadcast Version'
  def version
    require './config/environment'
    Notifications::AppVersionJob.set(wait: 1.minute).perform_later
  end
end
