# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.secrets[:mailer_default_from].to_s

  layout 'mailer'
end
