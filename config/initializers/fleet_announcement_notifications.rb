# frozen_string_literal: true

Rails.application.config.after_initialize do
  Notifications::InApp::FleetAnnouncementSubscriber.register!
end
