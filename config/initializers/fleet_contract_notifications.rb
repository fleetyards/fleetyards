# frozen_string_literal: true

Rails.application.config.after_initialize do
  Notifications::InApp::FleetContractSubscriber.register!
end
