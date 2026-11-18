# frozen_string_literal: true

require "test_helper"

# What a berth is built for: so many of a class, at once. The entries on one
# dock are alternatives -- a deck that takes one large ship or two mediums
# carries both.
class DockCapacityTest < ActiveSupport::TestCase
  test "a dock carries alternatives rather than a sum" do
    dock = create(:dock, dock_type: :hangar)
    create(:dock_capacity, dock:, ladder: :ship, size: "large", quantity: 1)
    create(:dock_capacity, dock:, ladder: :ship, size: "medium", quantity: 2)

    assert_equal 2, dock.reload.capacities.count
  end

  test "both ladders can sit under one dock" do
    dock = create(:dock, dock_type: :cargogrid)
    create(:dock_capacity, dock:, ladder: :ship, size: "extra_extra_small", quantity: 1)
    create(:dock_capacity, dock:, ladder: :vehicle, size: "large", quantity: 6)

    assert_equal %w[ship vehicle], dock.reload.capacities.map(&:ladder).sort
  end

  test "a class has to be on the ladder it claims" do
    entry = build(:dock_capacity, ladder: :ship, size: "extra_extra_large")

    assert_not entry.valid?
    assert_includes entry.errors.attribute_names, :size
  end

  # The ladders overlap in wording and not in membership: `capital` is a pad
  # class, `extra_extra_large` a vehicle one, and neither belongs to the other.
  test "a vehicle class is refused on the ship ladder and the reverse" do
    assert_not build(:dock_capacity, ladder: :vehicle, size: "capital").valid?
    assert build(:dock_capacity, ladder: :vehicle, size: "extra_extra_large").valid?
  end

  test "the same class cannot be recorded twice on one dock" do
    dock = create(:dock)
    create(:dock_capacity, dock:, ladder: :ship, size: "small", quantity: 1)
    duplicate = build(:dock_capacity, dock:, ladder: :ship, size: "small", quantity: 3)

    assert_not duplicate.valid?
  end

  test "the same class on the other ladder is a different entry" do
    dock = create(:dock)
    create(:dock_capacity, dock:, ladder: :ship, size: "small", quantity: 1)

    assert build(:dock_capacity, dock:, ladder: :vehicle, size: "small", quantity: 1).valid?
  end

  test "a berth takes at least one of whatever it takes" do
    assert_not build(:dock_capacity, quantity: 0).valid?
    assert_not build(:dock_capacity, quantity: -1).valid?
  end

  # The label is rendered from one entry, so only one can claim it.
  test "only one entry per dock is the display one" do
    dock = create(:dock)
    create(:dock_capacity, dock:, ladder: :ship, size: "small", display: true)
    second = build(:dock_capacity, dock:, ladder: :ship, size: "medium", display: true)

    assert_not second.valid?
    assert_includes second.errors.attribute_names, :display
  end

  test "another dock's display entry is no conflict" do
    create(:dock_capacity, dock: create(:dock), ladder: :ship, size: "small", display: true)

    assert build(:dock_capacity, dock: create(:dock), ladder: :ship, size: "small", display: true).valid?
  end

  test "a dock without a display entry has no label to render" do
    dock = create(:dock)
    create(:dock_capacity, dock:, ladder: :ship, size: "small")

    assert_nil dock.reload.display_capacity
  end

  test "the display entry is what the label comes from" do
    dock = create(:dock)
    create(:dock_capacity, dock:, ladder: :ship, size: "medium", quantity: 2, display: true)

    entry = dock.reload.display_capacity

    assert_equal 2, entry.quantity
    assert_equal "Medium (M)", entry.size_label
  end

  test "the label counts the flagged entry's class" do
    dock = create(:dock, ship_size: :small)
    create(:dock_capacity, dock:, ladder: :ship, size: "large", quantity: 1)
    create(:dock_capacity, dock:, ladder: :ship, size: "medium", quantity: 2, display: true)

    assert_equal "2 medium pads", dock.reload.display_label
  end

  test "a single entry reads in the singular" do
    entry = build(:dock_capacity, ladder: :vehicle, size: "large", quantity: 1)

    assert_equal "1 large vehicle bay", entry.display_label
  end

  test "the label follows the reader's locale" do
    entry = build(:dock_capacity, ladder: :ship, size: "medium", quantity: 2)

    I18n.with_locale(:de) do
      assert_equal "2 mittelgroße Landeplätze", entry.display_label
    end
  end

  # Read from the backend rather than through `I18n.t`, which would fall back
  # to English and hide a missing locale.
  test "every class on both ladders has a label in every locale" do
    translations = I18n.backend.translations(do_init: true)

    DockCapacity::LADDER_CLASSES.each do |ladder, sizes|
      sizes.each do |size|
        I18n.available_locales.each do |locale|
          forms = translations.dig(locale, :labels, :dock_capacity, ladder.to_sym, size.to_sym)

          assert forms&.key?(:one) && forms.key?(:other), "#{locale} has no label for #{ladder} #{size}"
        end
      end
    end
  end

  # A class says nothing about how many, so an undescribed berth keeps the
  # pad class it always showed instead of claiming a count.
  test "a dock without a flagged entry reads as its pad class" do
    dock = create(:dock, ship_size: :small)
    create(:dock_capacity, dock:, ladder: :ship, size: "medium", quantity: 2)

    assert_equal "Small (S)", dock.reload.display_label
  end

  # `Model.vehicle_size_filters` humanizes the curated ladder, so this matches
  # what the filter already shows rather than inventing a second wording.
  test "a vehicle class reads as the filter shows it" do
    entry = build(:dock_capacity, ladder: :vehicle, size: "extra_extra_small")

    assert_equal "Extra extra small", entry.size_label
  end

  test "a dock takes its entries with it" do
    dock = create(:dock)
    create(:dock_capacity, dock:)

    assert_difference -> { DockCapacity.count }, -1 do
      dock.destroy
    end
  end
end
