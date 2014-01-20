require 'test_helper'
require 'ships_loader'

class ShipsLoaderTest < ActiveSupport::TestCase

  test "should create correct equipment and add them to ship" do
    ship = create :ship
    type = Equipment::VALID_TYPES.first
    data = {
      "#{type}_name" => [{
        name: "Warpcore",
        count: 2
      }]
    }
    ShipsLoader.create_equipment ship, data

    ship.reload
    phaser = Equipment.where(name: "Warpcore").first
    assert_equal ship.equipment.to_a, [phaser, phaser]
  end

  test "should create correct weapons and add them to ship" do
    ship = create :ship
    hp_class = Weapon::VALID_CLASSES.first
    data = {
      "#{hp_class}_name" => [{
        name: "Phaser",
        count: 2
      }]
    }
    ShipsLoader.create_weapons ship, data

    ship.reload
    phaser = Weapon.where(name: "Phaser").first
    assert_equal ship.weapons.to_a, [phaser, phaser]
  end
end
