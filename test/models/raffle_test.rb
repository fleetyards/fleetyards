# frozen_string_literal: true

require "test_helper"

class RaffleTest < ActiveSupport::TestCase
  test "status follows the dates once published" do
    assert_equal "draft", build(:raffle, :draft).status
    assert_equal "upcoming", build(:raffle, :upcoming).tap(&:validate).status
    assert_equal "open", build(:raffle).tap(&:validate).status
    assert_equal "closed", build(:raffle, :closed).tap(&:validate).status
    assert_equal "drawn", build(:raffle, :closed, drawn_at: Time.current).tap(&:validate).status
    assert_equal "concluded", build(:raffle, :closed, drawn_at: 1.hour.ago, concluded_at: Time.current).tap(&:validate).status
  end

  test "the close is the start plus the run length" do
    starts_at = Time.zone.local(2026, 11, 1, 18)
    raffle = create(:raffle, starts_at:, run_days: 14)

    assert_equal starts_at + 14.days, raffle.ends_at
  end

  test "current is the running raffle, else the next, else the last" do
    last = create(:raffle, :closed)
    assert_equal last, Raffle.current

    upcoming = create(:raffle, :upcoming)
    assert_equal upcoming, Raffle.current

    running = create(:raffle)
    create(:raffle, :draft)
    assert_equal running, Raffle.current
  end

  test "a published raffle needs a prize" do
    raffle = build(:raffle, prize: nil)

    assert_not raffle.valid?
    assert raffle.errors.added?(:prize, :blank)
  end

  test "a published raffle needs a code" do
    raffle = build(:raffle, code: nil)

    assert_not raffle.valid?
    assert raffle.errors.added?(:code, :blank)
    assert build(:raffle, :draft, code: nil).valid?
  end

  test "a published raffle needs an image" do
    raffle = build(:raffle, images: [])

    assert_not raffle.valid?
    assert raffle.errors.added?(:images, :blank)
    assert build(:raffle, :draft, images: []).valid?
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

  test "the code, dates and periods are frozen after the draw" do
    raffle = create(:raffle, :closed, drawn_at: Time.current)

    assert_not raffle.update(code: "OTHER")
    assert raffle.errors.added?(:code, :frozen_after_draw)
    assert_not raffle.reload.update(claim_period_days: 1)
    assert raffle.reload.update(title: "Renamed")
  end

  test "masked_code shows the last four characters of a long code only" do
    assert_equal "********CDEF", build(:raffle, code: "12345678CDEF").masked_code
    assert_equal "******", build(:raffle, code: "ABCDEF").masked_code
  end

  test "orders the gallery by upload" do
    raffle = create(:raffle, :draft, images: [])
    first = uploaded("first.png")
    second = travel(1.minute) { uploaded("second.png") }
    raffle.images.attach(second, first)

    assert_equal %w[first.png second.png], raffle.reload.ordered_images.map { |image| image.filename.to_s }
  end

  test "a drawn raffle cannot be deleted" do
    raffle = create(:raffle, :closed, drawn_at: Time.current)

    assert_not raffle.destroy
    assert Raffle.exists?(raffle.id)
  end

  test "conclude! drops the email snapshots" do
    raffle = create(:raffle)
    entry = create(:raffle_entry, raffle:)

    raffle.conclude!

    assert raffle.concluded?
    assert_nil entry.reload.email
  end

  test "announcement scopes find a running raffle once per kind" do
    raffle = create(:raffle, starts_at: 1.hour.ago, run_days: 3)

    assert_includes Raffle.start_unannounced, raffle
    assert_not_includes Raffle.last_day_unannounced, raffle

    travel 2.days + 2.hours do
      assert_includes Raffle.last_day_unannounced, raffle
    end

    raffle.update_columns(start_announced_at: Time.current)
    assert_not_includes Raffle.start_unannounced, raffle
  end

  private def uploaded(filename)
    ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test/fixtures/files/test.png")), filename:, content_type: "image/png"
    )
  end
end
