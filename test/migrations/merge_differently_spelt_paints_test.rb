# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20261123120000_merge_differently_spelt_paints.rb")

class MergeDifferentlySpeltPaintsTest < ActiveSupport::TestCase
  test "merges the old spelling into the paint most ships carry, under the hangar's name" do
    carrack = create(:model, name: "Carrack")
    old = create(:model_paint, model: carrack, name: "Best in Show 2952 (Red Alert)")
    current = create(:model_paint, model: carrack, name: "2952 Best in Show")
    owners = create_list(:vehicle, 2, model: carrack)
    owners.each { |vehicle| VehiclePaint.create!(vehicle:, model_paint: old) }
    other = create(:vehicle, model: carrack)
    VehiclePaint.create!(vehicle: other, model_paint: current)

    MergeDifferentlySpeltPaints.new.up

    assert_not ModelPaint.exists?(current.id)
    assert_equal "2952 Best in Show", old.reload.name
    assert_equal [old.id], other.reload.model_paint_ids
  end

  test "keeps the store's own record so the store import does not make it again" do
    mole = create(:model, name: "MOLE")
    store = create(:model_paint, model: mole, name: "Mole Carbon Edition", rsi_id: 202)
    hangar = create(:model_paint, model: mole, name: "Carbon")
    create_list(:vehicle, 2, model: mole).each { |vehicle| VehiclePaint.create!(vehicle:, model_paint: hangar) }

    MergeDifferentlySpeltPaints.new.up

    assert_not ModelPaint.exists?(hangar.id)
    assert_equal ["Carbon"], mole.reload.paints.pluck(:name)
    assert_equal 2, store.reload.vehicle_paints.count
  end

  test "gives every Best in Show year one capitalisation" do
    f8c = create(:model, name: "F8C Lightning")
    current = create(:model_paint, model: f8c, name: "2954 Best In Show")
    create(:model_paint, model: f8c, name: "Best In Show 2954")
    spirit = create(:model, name: "C1 Spirit")
    create(:model_paint, model: spirit, name: "2956 Best In Show")

    MergeDifferentlySpeltPaints.new.up

    assert_equal [current.id], f8c.reload.paints.pluck(:id)
    assert_equal ["2954 Best in Show"], f8c.paints.pluck(:name)
    assert_equal ["2956 Best in Show"], spirit.reload.paints.pluck(:name)
  end

  test "keeps a visible paint over a hidden one" do
    reclaimer = create(:model, name: "Reclaimer")
    visible = create(:model_paint, model: reclaimer, name: "Hadinite", hidden: false)
    hidden = create(:model_paint, model: reclaimer, name: "Hadanite", hidden: true)

    MergeDifferentlySpeltPaints.new.up

    assert_not ModelPaint.exists?(hidden.id)
    assert_equal "Hadanite", visible.reload.name
  end

  test "renames a paint with no second copy and links its pledges" do
    phoenix = create(:model, name: "Constellation Mk IV Phoenix")
    paint = create(:model_paint, model: phoenix, name: "Black Heron")
    item = create(:hangar_pledge_item, name: "Constellation Mk IV - Heron Black Paint")

    MergeDifferentlySpeltPaints.new.up

    assert_equal "Heron Black", paint.reload.name
    assert_equal [paint.id], item.reload.model_paints.pluck(:id)
  end

  test "leaves the same spelling on another ship alone" do
    carrack = create(:model, name: "Carrack")
    create(:model_paint, model: carrack, name: "Best in Show 2950")
    cutlass = create(:model, name: "Cutlass Black")
    paint = create(:model_paint, model: cutlass, name: "Akuma")

    MergeDifferentlySpeltPaints.new.up

    assert_equal "Akuma", paint.reload.name
    assert_equal ["2950 Best in Show"], carrack.reload.paints.pluck(:name)
  end
end
