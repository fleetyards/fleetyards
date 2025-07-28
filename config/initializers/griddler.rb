# frozen_string_literal: true

Rails.application.reloader.to_prepare do
  Griddler.configure do |config|
    config.processor_class = EmailProcessor
    config.email_class = Griddler::Email
    config.processor_method = :process
    config.email_service = :postmark
  end
end
