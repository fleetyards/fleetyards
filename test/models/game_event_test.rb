# frozen_string_literal: true

require "test_helper"

class GameEventTest < ActiveSupport::TestCase
  test "requires a title and a start" do
    event = GameEvent.new

    assert_not event.valid?
    assert event.errors.of_kind?(:title, :blank)
    assert event.errors.of_kind?(:starts_at, :blank)
  end

  test "rejects an end before the start" do
    event = build(:game_event, starts_at: 2.days.from_now, ends_at: 1.day.from_now)

    assert_not event.valid?
    assert event.errors.of_kind?(:ends_at, :invalid)
  end

  test "rejects a link that is not http" do
    assert_not build(:game_event, url: "javascript:alert(1)").valid?
    assert build(:game_event, url: "https://robertsspaceindustries.com/comm-link").valid?
  end

  test "overlapping finds events that touch the window" do
    inside = create(:game_event, starts_at: 2.days.from_now, ends_at: 3.days.from_now)
    create(:game_event, starts_at: 20.days.from_now, ends_at: 21.days.from_now)

    assert_equal [inside], GameEvent.overlapping(Time.current, 7.days.from_now).to_a
  end
end
