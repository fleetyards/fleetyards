# frozen_string_literal: true

require "test_helper"

class FleetNotificationSettingDigestTest < ActiveSupport::TestCase
  setup do
    @fleet = create(:fleet)
    # Mondays at 18:00 Berlin time.
    @setting = @fleet.create_fleet_notification_setting!(
      discord_digest_weekday: 1, discord_digest_time: "18:00", discord_digest_timezone: "Europe/Berlin"
    )
  end

  def berlin(string)
    ActiveSupport::TimeZone["Europe/Berlin"].parse(string)
  end

  test "the slot is the most recent scheduled moment in the fleet's timezone" do
    assert_equal berlin("2026-09-21 18:00"), @setting.digest_slot(berlin("2026-09-24 12:00"))
    assert_equal berlin("2026-09-21 18:00"), @setting.digest_slot(berlin("2026-09-21 18:00"))
    assert_equal berlin("2026-09-14 18:00"), @setting.digest_slot(berlin("2026-09-21 17:59"))
  end

  test "due from its slot until the grace runs out" do
    assert @setting.digest_due?(berlin("2026-09-21 18:10"))
    assert_not @setting.digest_due?(berlin("2026-09-21 19:30"))
  end

  test "not due again once sent for this slot" do
    @setting.update!(discord_digest_sent_at: berlin("2026-09-21 18:01"))

    assert_not @setting.digest_due?(berlin("2026-09-21 18:15"))
    assert @setting.digest_due?(berlin("2026-09-28 18:05"))
  end

  test "moving the time later on the day it was sent does not send it again" do
    @setting.update!(discord_digest_sent_at: berlin("2026-09-21 18:01"), discord_digest_time: "18:30")

    assert_not @setting.digest_due?(berlin("2026-09-21 18:31"))
    assert @setting.digest_due?(berlin("2026-09-28 18:31"))
  end

  # 02:30 happens twice when the clocks go back.
  test "the repeated hour at the end of summer time sends once" do
    @setting.update!(discord_digest_weekday: 0, discord_digest_time: "02:30")
    zone = ActiveSupport::TimeZone["Europe/Berlin"]
    first = zone.local(2026, 10, 25, 2, 30)
    @setting.update!(discord_digest_sent_at: first + 1.minute)

    assert_not @setting.digest_due?(first + 1.hour + 5.minutes)
  end

  test "a UTC evening is the next morning in the fleet's zone" do
    @setting.update!(discord_digest_timezone: "Asia/Tokyo")

    # Monday 18:00 in Tokyo is Monday 09:00 UTC.
    assert @setting.reload.digest_due?(Time.utc(2026, 9, 21, 9, 5))
  end

  test "rejects a zone that does not exist" do
    @setting.discord_digest_timezone = "Mars/Olympus"

    assert_not @setting.valid?
  end

  test "off without a weekday" do
    @setting.update!(discord_digest_weekday: nil, discord_digest_time: nil)

    assert_nil @setting.digest_slot
    assert_not @setting.digest_due?
  end

  test "a weekday needs a time" do
    @setting.discord_digest_time = nil

    assert_not @setting.valid?
    assert @setting.errors.added?(:discord_digest_time, :blank)
  end

  test "rejects a time that is not HH:MM" do
    @setting.discord_digest_time = "25:00"

    assert_not @setting.valid?
  end
end
