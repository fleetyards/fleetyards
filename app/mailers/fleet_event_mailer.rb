# frozen_string_literal: true

class FleetEventMailer < ApplicationMailer
  def published(notification) = deliver_event(notification, :published)

  def locked(notification) = deliver_event(notification, :locked)

  def starting_soon(notification) = deliver_event(notification, :starting_soon)

  def started(notification) = deliver_event(notification, :started)

  def completed(notification) = deliver_event(notification, :completed)

  def cancelled(notification) = deliver_event(notification, :cancelled)

  def signup_added(notification) = deliver_event(notification, :signup_added)

  def signup_withdrawn(notification) = deliver_event(notification, :signup_withdrawn)

  def signup_confirmed(notification) = deliver_event(notification, :signup_confirmed)

  def signup_assigned(notification) = deliver_event(notification, :signup_assigned)

  def signup_kicked(notification) = deliver_event(notification, :signup_kicked)

  private

  def deliver_event(notification, key)
    @notification = notification
    @event = notification.record
    @user = notification.user
    @key = key
    mail(
      to: @user.email,
      template_name: "event_notification",
      subject: I18n.t("mailer.fleet_event.#{key}.subject", title: @event.title)
    )
  end
end
