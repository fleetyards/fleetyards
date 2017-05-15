# encoding: utf-8
# frozen_string_literal: true

class UserMailer < ActionMailer::Base
  default from: Rails.application.secrets[:mailer_default_from].to_s

  def notify_admin(user)
    user_info(user)
    mail(
      to: Rails.application.secrets[:mailer_admin_mail],
      subject: I18n.t(:"mailer.user.admin.subject"),
      template_name: 'admin'
    )
  end

  def user_info(user)
    @user_info ||= %w[email username].map do |field|
      "#{I18n.t("activerecord.attributes.user.#{field}")}: #{user.send(field)}"
    end
  end
end
