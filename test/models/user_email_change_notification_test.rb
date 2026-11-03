# frozen_string_literal: true

require "test_helper"

class UserEmailChangeNotificationTest < ActiveSupport::TestCase
  def notifications_sent_while_changing_email(user)
    sent = []
    user.define_singleton_method(:send_devise_notification) { |notification, *args| sent << [notification, *args] }

    user.update!(email: "pilot@example.org")

    sent
  end

  test "tells the old address about the change" do
    user = create(:user, email: "old@example.org")

    sent = notifications_sent_while_changing_email(user)

    assert_includes sent, [:email_changed, {to: "old@example.org"}]
  end

  test "does not write to a placeholder address" do
    user = create(:user, email: "#{SecureRandom.uuid}@#{User::PLACEHOLDER_EMAIL_DOMAIN}")

    sent = notifications_sent_while_changing_email(user)

    assert_equal [:confirmation_instructions], sent.map(&:first)
    assert_equal({to: "pilot@example.org"}, sent.first.last)
  end
end
