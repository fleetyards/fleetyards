require 'test_helper'
require 'ships_loader'

class ShipsLoaderTest < ActiveSupport::TestCase

  test "should create correct equipment and add them to ship" do
    ship = create :ship
    type = Equipment::VALID_TYPES.first
    data = {
      type => [{
        name: "Warpcore",
        count: 2
      }]
    }
    ShipsLoader.create_equipment ship, data

    ship.reload
    warpcore = Equipment.where(name: "Warpcore").first
    assert_equal ship.equipment.to_a, [warpcore, warpcore]

    data = {
      type => [{
        name: "Warpcore",
        count: 2
      }]
    }
    ShipsLoader.create_equipment ship, data

    ship.reload
    warpcore = Equipment.where(name: "Warpcore").first
    assert_equal ship.equipment.to_a, [warpcore, warpcore]
  end

  test "should create correct weapons and add them to ship" do
    ship = create :ship
    hp_class = Weapon::VALID_CLASSES.first
    data = {
      hp_class => [{
        name: "Phaser",
        count: 2
      }]
    }
    ShipsLoader.create_weapons ship, data

    ship.reload
    phaser = Weapon.where(name: "Phaser").first
    assert_equal ship.weapons.to_a, [phaser, phaser]
  end

  test "should calculate the correct items" do
    hp_class = Weapon::VALID_CLASSES.first
    data1 = "2x2 Talon Stalker IR (underwing)"

    result1 = ShipsLoader.add_item hp_class, data1

    assert_equal result1, {"#{hp_class}_count" => 4, "#{hp_class}" => [{name: "Talon Stalker IR", count: 4}]}

    data2 = "2x Joker Suckerpunch distortion cannon (wings)<br />1x Kruger Intergalaktische Tigerstreik T-21 (nose)"

    result2 = ShipsLoader.add_item hp_class, data2

    assert_equal result2, {}

    data3 = "2x Behring Marksman HS Missile 8-pack<br />(4 additional available)"

    result3 = ShipsLoader.add_item hp_class, data3

    assert_equal result3, {}
  end
end
