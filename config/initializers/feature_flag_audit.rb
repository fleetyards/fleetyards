# frozen_string_literal: true

Rails.application.config.after_initialize do
  FeatureFlags::AuditSubscriber.register!
end
