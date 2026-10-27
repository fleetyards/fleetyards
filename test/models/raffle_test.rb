# frozen_string_literal: true

require "test_helper"

class RaffleTest < ActiveSupport::TestCase
  test "status follows the dates once published" do
    assert_equal "draft", build(:raffle, :draft).status
    assert_equal "upcoming", build(:raffle, :upcoming).status
    assert_equal "open", build(:raffle).status
    assert_equal "closed", build(:raffle, :closed).status
    assert_equal "drawn", build(:raffle, :closed, drawn_at: Time.current).status
    assert_equal "concluded", build(:raffle, :closed, drawn_at: 1.hour.ago, concluded_at: Time.current).status
  end

  test "a published raffle needs a code" do
    raffle = build(:raffle, code: nil)

    assert_not raffle.valid?
    assert raffle.errors.added?(:code, :blank)
    assert build(:raffle, :draft, code: nil).valid?
  end

  test "the end has to be after the start" do
    raffle = build(:raffle, starts_at: 1.day.from_now, ends_at: 1.hour.from_now)

    assert_not raffle.valid?
    assert raffle.errors.added?(:ends_at, :invalid)
  end

  test "the code is encrypted at rest" do
    raffle = create(:raffle, code: "SECRET-CODE")

    stored = Raffle.connection.select_value("SELECT code FROM raffles WHERE id = '#{raffle.id}'")

    assert_not_includes stored, "SECRET-CODE"
    assert_equal "SECRET-CODE", raffle.reload.code
  end

  test "the code stays out of the version history" do
    raffle = create(:raffle, code: "SECRET-CODE")
    raffle.update!(title: "Renamed")

    raffle.versions.each do |version|
      assert_not_includes version.object.to_s, "SECRET-CODE"
      assert_not_includes version.object_changes.to_s, "SECRET-CODE" if version.respond_to?(:object_changes)
    end
  end

  test "the code and dates are frozen after the draw" do
    raffle = create(:raffle, :closed, drawn_at: Time.current)

    assert_not raffle.update(code: "OTHER")
    assert raffle.errors.added?(:code, :frozen_after_draw)
    assert raffle.reload.update(title: "Renamed")
  end

  test "masked_code shows only the last four characters" do
    assert_equal "********CDEF", build(:raffle, code: "12345678CDEF").masked_code
    assert_equal "******", build(:raffle, code: "ABCDEF").masked_code
  end

  test "conclude! drops the email snapshots" do
    raffle = create(:raffle)
    entry = create(:raffle_entry, raffle:)
    assert entry.reload.email.present?

    raffle.conclude!

    assert raffle.concluded?
    assert_nil entry.reload.email
  end
end
