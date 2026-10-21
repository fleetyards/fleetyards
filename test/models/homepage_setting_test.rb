# frozen_string_literal: true

require "test_helper"

class HomepageSettingTest < ActiveSupport::TestCase
  test "features only ships a visitor can open" do
    shown = create(:model)
    hidden = create(:model, hidden: true)
    setting = HomepageSetting.create!(featured_model_ids: [shown.id, hidden.id, SecureRandom.uuid])

    assert_equal [shown], setting.featured_models.to_a
  end

  test "features only the chosen ships" do
    ships = create_list(:model, 2)
    setting = HomepageSetting.create!(featured_model_ids: ships.map(&:id))

    picks = Array.new(60) { |offset| setting.featured_ship(day: Date.new(2026, 10, 1) + offset) }

    assert_equal ships.to_set, picks.to_set
  end

  # Everyone sees the same ship on a given day, however often they come back.
  test "features the same ship all day" do
    ships = create_list(:model, 5)
    setting = HomepageSetting.create!(featured_model_ids: ships.map(&:id))
    day = Date.new(2026, 10, 22)

    picks = Array.new(10) { HomepageSetting.find(setting.id).featured_ship(day:) }

    assert_equal 1, picks.uniq.size
  end

  test "features the first ship of the list while the draw is off" do
    first, second = create_list(:model, 2)
    setting = HomepageSetting.create!(featured_model_ids: [second.id, first.id], featured_random: false)

    picks = Array.new(20) { |offset| setting.featured_ship(day: Date.new(2026, 10, 1) + offset) }

    assert_equal [second], picks.uniq
  end

  # Nobody curating is the usual case: the hero then takes any ship drawn with
  # the picture it is built around.
  test "features a ship with a coloured angled render when none are set" do
    rendered = create(:model)
    rendered.angled_view_colored.attach(io: File.open(Rails.root.join("test/fixtures/files/test.png")), filename: "angled.png")
    create(:model)
    create(:model, hidden: true).angled_view_colored.attach(io: File.open(Rails.root.join("test/fixtures/files/test.png")), filename: "angled.png")

    assert_equal rendered, HomepageSetting.new.featured_ship
  end

  test "features the same rendered ship all day when none are set" do
    3.times do
      create(:model).angled_view_colored.attach(io: File.open(Rails.root.join("test/fixtures/files/test.png")), filename: "angled.png")
    end
    day = Date.new(2026, 10, 22)

    picks = Array.new(5) { HomepageSetting.new.featured_ship(day:) }

    assert_equal 1, picks.uniq.size
  end

  test "features nothing when no ship has a coloured angled render" do
    create(:model)

    assert_nil HomepageSetting.new.featured_ship
  end

  test "features nothing while the feature is switched off" do
    ship = create(:model)
    setting = HomepageSetting.create!(featured_model_ids: [ship.id], featured_random: false, featured_hidden: true)

    assert_nil setting.featured_ship
  end

  test "keeps each ship once and no more than the cap" do
    ship = create(:model)
    setting = HomepageSetting.new(featured_model_ids: [ship.id, ship.id, ""])

    assert setting.valid?
    assert_equal [ship.id], setting.featured_model_ids

    setting.featured_model_ids = Array.new(HomepageSetting::MAX_FEATURED_MODELS + 1) { SecureRandom.uuid }

    assert_not setting.valid?
  end
end
