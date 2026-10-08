# frozen_string_literal: true

require "test_helper"

class TerminalTest < ActiveSupport::TestCase
  test "a station is not on a surface, even over a planet" do
    station = create(:terminal, space_station: "ARC-L1 Wide Forest Station", city: nil, outpost: nil)

    assert_not station.on_surface?
    assert_not_includes Terminal.on_surface, station
  end

  test "a city or an outpost is on a surface" do
    city = create(:terminal, city: "Area 18")
    outpost = create(:terminal, outpost: "Shubin SM0-10")

    assert city.on_surface?
    assert outpost.on_surface?
    assert_equal [city, outpost].sort_by(&:id), Terminal.on_surface.sort_by(&:id)
  end

  test "a terminal with no place recorded is not called a surface" do
    unknown = create(:terminal)

    assert_not unknown.on_surface?
    assert_not_includes Terminal.on_surface, unknown
  end
end
